extends RefCounted
## SIM-GATE-01: the project's one XLSX writer (Office Open XML SpreadsheetML with DrawingML charts), written with Godot's
## ZIPPacker and nothing else. The desktop game's live recording export (live_export.gd) and the CI simulation gate's
## workbook (tests/sim_workbook.gd, run headless by tools/sim_suite.py) both use it. Desktop and CI only: the Android export
## preset excludes this folder (game/export_presets.cfg, checked by tests/test_sim_gate.py). No class_name, so nothing in the
## shipped game refers to it by name; callers load() or preload() the script.
##
## Streaming, so memory stays bounded by one row: begin_sheet(name, header, widths), row(values) any number of times,
## chart(...) for charts drawn from that sheet's columns, end_sheet(); then close(). Cells: int and float become numbers,
## bool a boolean, null an empty cell, anything else text (inline strings; no shared-string table to hold in memory).
## The header row is bold and frozen. A chart references cell ranges of its own sheet and also carries the values as a cache
## (programs such as LibreOffice draw from the cache), for sheets of at most CACHE_ROWS rows: a sheet meant for a chart is
## kept that short (hourly or daily series), so the cache bounds memory too. Series colours: the validated categorical
## palette (dataviz reference, light mode) in fixed order, at most four series a chart.
##
##   var x = preload("res://scripts/recorder_export/xlsx_writer.gd").new()
##   x.open("/tmp/a.xlsx"); x.begin_sheet("Data", ["hour", "people"]); x.row([0, 104]); x.row([1, 104])
##   x.chart({"type": "line", "title": "People", "x_col": 0, "y_cols": [1], "first_row": 2, "last_row": 3})
##   x.end_sheet(); x.close()

const MAX_ROWS := 1048576
const MAX_SHEET_NAME := 31
const CACHE_ROWS := 5000
const CHART_COL := 20
const SERIES_COLOURS := ["2a78d6", "eb6834", "1baf7a", "eda100", "e87ba4", "008300", "6250d6", "e34948"]
const NS_MAIN := "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
const NS_REL := "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
const NS_PKG_REL := "http://schemas.openxmlformats.org/package/2006/relationships"
const NS_C := "http://schemas.openxmlformats.org/drawingml/2006/chart"
const NS_A := "http://schemas.openxmlformats.org/drawingml/2006/main"
const NS_XDR := "http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
const CT_SHEET := "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"
const CT_DRAWING := "application/vnd.openxmlformats-officedocument.drawing+xml"
const CT_CHART := "application/vnd.openxmlformats-officedocument.drawingml.chart+xml"

var zip: ZIPPacker
var path := ""
var sheets: Array = []          # {name, rows, charts: [spec], index}
var cur: Dictionary = {}        # the sheet being written
var chart_count := 0
var error := ""                 # the first error, "" when none
var _buf := PackedStringArray() # rows not yet handed to the zip (written in batches)


## Start the workbook file. Returns false (and sets `error`) if the file cannot be made.
func open(file_path: String) -> bool:
	path = file_path
	zip = ZIPPacker.new()
	var e := zip.open(file_path)
	if e != OK:
		error = "cannot create %s (error %d)" % [file_path, e]
		return false
	return true


static func safe_sheet_name(name: String) -> String:
	var s := name
	for ch in ["[", "]", ":", "*", "?", "/", "\\"]:
		s = s.replace(ch, " ")
	return s.strip_edges().left(MAX_SHEET_NAME)


## A1-style column letters for a 0-based column.
static func col_name(c: int) -> String:
	var s := ""
	var n := c + 1
	while n > 0:
		var r := (n - 1) % 26
		s = char(65 + r) + s
		n = (n - 1) / 26
	return s


static func xml_text(v) -> String:
	var s := str(v)
	var out := ""
	for i in s.length():
		var code := s.unicode_at(i)
		if code < 32 and code != 9 and code != 10 and code != 13:
			continue                                  # characters XML 1.0 does not allow
		out += s[i]
	return out.xml_escape(true)


func begin_sheet(name: String, header: Array, widths := []) -> void:
	if not cur.is_empty():
		end_sheet()
	var nm := safe_sheet_name(name)
	cur = {"name": nm, "rows": 0, "charts": [], "index": sheets.size() + 1, "cols": header.size(), "cache": [header.duplicate()]}
	zip.start_file("xl/worksheets/sheet%d.xml" % cur.index)
	var head := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="%s" xmlns:r="%s">' % [NS_MAIN, NS_REL]
	head += '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
	head += '<sheetFormatPr defaultRowHeight="15"/><cols>'
	for i in header.size():
		var wdt: float = float(widths[i]) if i < widths.size() else clampf(str(header[i]).length() * 1.1 + 2.0, 8.0, 60.0)
		head += '<col min="%d" max="%d" width="%.1f" customWidth="1"/>' % [i + 1, i + 1, wdt]
	head += '</cols><sheetData>'
	zip.write_file(head.to_utf8_buffer())
	_row(header, true)


func row(values: Array) -> void:
	if cur.is_empty() or int(cur.rows) >= MAX_ROWS:
		return
	_row(values, false)


func _row(values: Array, bold: bool) -> void:
	cur.rows = int(cur.rows) + 1
	var r := int(cur.rows)
	if not bold and r <= CACHE_ROWS:
		(cur.cache as Array).append(values.duplicate())
	var parts := PackedStringArray(['<row r="%d">' % r])
	for i in values.size():
		var v = values[i]
		var ref := col_name(i) + str(r)
		var st := ' s="1"' if bold else ""
		match typeof(v):
			TYPE_NIL:
				continue
			TYPE_INT:
				parts.append('<c r="%s"%s><v>%d</v></c>' % [ref, st, v])
			TYPE_FLOAT:
				if is_nan(v) or is_inf(v):
					parts.append('<c r="%s"%s t="inlineStr"><is><t>%s</t></is></c>' % [ref, st, str(v)])
				else:
					parts.append('<c r="%s"%s><v>%s</v></c>' % [ref, st, _num(v)])
			TYPE_BOOL:
				parts.append('<c r="%s"%s t="b"><v>%d</v></c>' % [ref, st, 1 if v else 0])
			_:
				var t = v if v is String else JSON.stringify(v)
				parts.append('<c r="%s"%s t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % [ref, st, xml_text(str(t).left(32000))])
	parts.append("</row>")
	_buf.append("".join(parts))
	if _buf.size() >= 256:
		_flush()


func _flush() -> void:
	if not _buf.is_empty():
		zip.write_file("".join(_buf).to_utf8_buffer())
		_buf = PackedStringArray()


static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)) and absf(v) < 1.0e15:
		return str(int(roundf(v)))
	return String.num(v, 6)


## A chart of this sheet's columns. spec: type "line" | "bar" | "scatter", title, x_col (0-based; its cells are the
## categories), y_cols [0-based], first_row and last_row (1-based data rows; the header row 1 names the series),
## optional header_row (1-based row whose cells name the series; default 1), x_title, y_title, anchor [col, row] (0-based
## top-left cell; default column CHART_COL, clear of tables up to 19 columns wide, one under another), size [cols, rows].
func chart(spec: Dictionary) -> void:
	if cur.is_empty():
		return
	var s := spec.duplicate(true)
	if int(s.get("last_row", 0)) < int(s.get("first_row", 2)):
		return                                         # no data rows: no chart (an empty chart would mislead)
	chart_count += 1
	s.id = chart_count
	if not s.has("anchor"):
		s.anchor = [maxi(CHART_COL, int(cur.cols) + 1), 1 + (cur.charts as Array).size() * 18]
	(cur.charts as Array).append(s)


func end_sheet() -> void:
	if cur.is_empty():
		return
	_flush()
	var tail := "</sheetData>"
	if not (cur.charts as Array).is_empty():
		tail += '<drawing r:id="rId1"/>'
	tail += "</worksheet>"
	zip.write_file(tail.to_utf8_buffer())
	zip.close_file()
	if (cur.charts as Array).is_empty():
		cur.cache = []                                 # nothing reads it: free it
	sheets.append(cur)
	cur = {}


func _put(name: String, text: String) -> void:
	zip.start_file(name)
	zip.write_file(text.to_utf8_buffer())
	zip.close_file()


## Write the workbook parts and close the file. Returns false on an error.
func close() -> bool:
	if not cur.is_empty():
		end_sheet()
	if sheets.is_empty():
		begin_sheet("Empty", ["nothing was recorded"])
		end_sheet()
	var ct := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
	ct += '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>'
	ct += '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
	ct += '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
	ct += '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
	var wb := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<workbook xmlns="%s" xmlns:r="%s"><bookViews><workbookView/></bookViews><sheets>' % [NS_MAIN, NS_REL]
	var wrels := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="%s">' % NS_PKG_REL
	var drawing := 0
	for sh in sheets:
		var i: int = sh.index
		ct += '<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="%s"/>' % [i, CT_SHEET]
		wb += '<sheet name="%s" sheetId="%d" r:id="rId%d"/>' % [xml_text(sh.name), i, i]
		wrels += '<Relationship Id="rId%d" Type="%s/worksheet" Target="worksheets/sheet%d.xml"/>' % [i, NS_REL, i]
		if (sh.charts as Array).is_empty():
			continue
		drawing += 1
		ct += '<Override PartName="/xl/drawings/drawing%d.xml" ContentType="%s"/>' % [drawing, CT_DRAWING]
		_put("xl/worksheets/_rels/sheet%d.xml.rels" % i, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="%s"><Relationship Id="rId1" Type="%s/drawing" Target="../drawings/drawing%d.xml"/></Relationships>' % [NS_PKG_REL, NS_REL, drawing])
		var dx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<xdr:wsDr xmlns:xdr="%s" xmlns:a="%s">' % [NS_XDR, NS_A]
		var drels := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="%s">' % NS_PKG_REL
		var k := 0
		for c in sh.charts:
			k += 1
			ct += '<Override PartName="/xl/charts/chart%d.xml" ContentType="%s"/>' % [int(c.id), CT_CHART]
			drels += '<Relationship Id="rId%d" Type="%s/chart" Target="../charts/chart%d.xml"/>' % [k, NS_REL, int(c.id)]
			var a: Array = c.anchor
			var size: Array = c.get("size", [10, 17])
			dx += '<xdr:twoCellAnchor editAs="oneCell"><xdr:from><xdr:col>%d</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>%d</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>' % [int(a[0]), int(a[1])]
			dx += '<xdr:to><xdr:col>%d</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>%d</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to>' % [int(a[0]) + int(size[0]), int(a[1]) + int(size[1])]
			dx += '<xdr:graphicFrame macro=""><xdr:nvGraphicFramePr><xdr:cNvPr id="%d" name="Chart %d"/><xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr>' % [k + 1, k]
			dx += '<xdr:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/></xdr:xfrm><a:graphic><a:graphicData uri="%s"><c:chart xmlns:c="%s" xmlns:r="%s" r:id="rId%d"/></a:graphicData></a:graphic></xdr:graphicFrame><xdr:clientData/></xdr:twoCellAnchor>' % [NS_C, NS_C, NS_REL, k]
			_put("xl/charts/chart%d.xml" % int(c.id), _chart_xml(sh.name, c, sh.cache if int(sh.rows) <= CACHE_ROWS else []))
		_put("xl/drawings/drawing%d.xml" % drawing, dx + "</xdr:wsDr>")
		_put("xl/drawings/_rels/drawing%d.xml.rels" % drawing, drels + "</Relationships>")
	ct += "</Types>"
	wb += "</sheets></workbook>"
	wrels += '<Relationship Id="rId%d" Type="%s/styles" Target="styles.xml"/></Relationships>' % [sheets.size() + 1, NS_REL]
	_put("[Content_Types].xml", ct)
	_put("_rels/.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="%s"><Relationship Id="rId1" Type="%s/officeDocument" Target="xl/workbook.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>' % [NS_PKG_REL, NS_REL])
	_put("docProps/core.xml", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>My Medieval Life simulation analysis</dc:title><dc:creator>My Medieval Life flight recorder</dc:creator></cp:coreProperties>')
	_put("xl/workbook.xml", wb)
	_put("xl/_rels/workbook.xml.rels", wrels)
	_put("xl/styles.xml", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<styleSheet xmlns="%s"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>' % NS_MAIN)
	var e := zip.close()
	if e != OK and error == "":
		error = "could not finish %s (error %d)" % [path, e]
	return error == ""


static func _ref(sheet: String, col: int, r0: int, r1: int) -> String:
	var q := "'%s'" % sheet.replace("'", "''")
	return xml_text("%s!$%s$%d:$%s$%d" % [q, col_name(col), r0, col_name(col), r1])


static func _rich(text: String, size := 1200) -> String:
	return '<c:tx><c:rich><a:bodyPr/><a:p><a:pPr><a:defRPr sz="%d" b="1"/></a:pPr><a:r><a:rPr lang="en-GB" sz="%d" b="1"/><a:t>%s</a:t></a:r></a:p></c:rich></c:tx><c:overlay val="0"/>' % [size, size, xml_text(text)]


## A cache of rows r0..r1 (1-based sheet rows) of column `col`: numbers (<c:numCache>) or text (<c:strCache>).
static func _cache(cache: Array, col: int, r0: int, r1: int, numeric: bool) -> String:
	if cache.is_empty():
		return ""
	var pts := PackedStringArray()
	var n := r1 - r0 + 1
	for r in range(r0, r1 + 1):
		var row: Array = cache[r - 1] if r - 1 < cache.size() else []
		var v = row[col] if col < row.size() else null
		if v == null:
			continue
		if numeric:
			if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
				pts.append('<c:pt idx="%d"><c:v>%s</c:v></c:pt>' % [r - r0, _num(float(v))])
		else:
			pts.append('<c:pt idx="%d"><c:v>%s</c:v></c:pt>' % [r - r0, xml_text(str(v))])
	if numeric:
		return '<c:numCache><c:formatCode>General</c:formatCode><c:ptCount val="%d"/>%s</c:numCache>' % [n, "".join(pts)]
	return '<c:strCache><c:ptCount val="%d"/>%s</c:strCache>' % [n, "".join(pts)]


func _chart_xml(sheet: String, c: Dictionary, cache := []) -> String:
	var kind := str(c.get("type", "line"))
	var r0 := int(c.get("first_row", 2))
	var r1 := int(c.last_row)
	var xcol := int(c.get("x_col", 0))
	var q := "'%s'" % sheet.replace("'", "''")
	var s := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<c:chartSpace xmlns:c="%s" xmlns:a="%s" xmlns:r="%s"><c:roundedCorners val="0"/><c:chart>' % [NS_C, NS_A, NS_REL]
	s += "<c:title>%s</c:title><c:autoTitleDeleted val=\"0\"/><c:plotArea><c:layout/>" % _rich(str(c.get("title", "")), 1300)
	var sers := ""
	var idx := 0
	var cat_numeric := kind != "bar"
	var hr := int(c.get("header_row", 1))
	for y in (c.y_cols as Array).slice(0, 4):
		var name_cache := _cache(cache, int(y), hr, hr, false)
		var tx := '<c:tx><c:strRef><c:f>%s</c:f>%s</c:strRef></c:tx>' % [xml_text("%s!$%s$%d" % [q, col_name(int(y)), hr]), name_cache]
		var colour: String = SERIES_COLOURS[idx % SERIES_COLOURS.size()]
		var cat_ref := '<c:%s><c:f>%s</c:f>%s</c:%s>' % ["numRef" if cat_numeric else "strRef", _ref(sheet, xcol, r0, r1), _cache(cache, xcol, r0, r1, cat_numeric), "numRef" if cat_numeric else "strRef"]
		var val_ref := '<c:numRef><c:f>%s</c:f>%s</c:numRef>' % [_ref(sheet, int(y), r0, r1), _cache(cache, int(y), r0, r1, true)]
		sers += '<c:ser><c:idx val="%d"/><c:order val="%d"/>%s' % [idx, idx, tx]
		if kind == "bar":
			sers += '<c:spPr><a:solidFill><a:srgbClr val="%s"/></a:solidFill></c:spPr><c:invertIfNegative val="0"/><c:cat>%s</c:cat><c:val>%s</c:val></c:ser>' % [colour, cat_ref, val_ref]
		elif kind == "scatter":
			sers += '<c:spPr><a:ln w="25400"><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:ln></c:spPr><c:marker><c:symbol val="none"/></c:marker><c:xVal>%s</c:xVal><c:yVal>%s</c:yVal><c:smooth val="0"/></c:ser>' % [colour, cat_ref, val_ref]
		else:
			sers += '<c:spPr><a:ln w="25400"><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:ln></c:spPr><c:marker><c:symbol val="none"/></c:marker><c:cat>%s</c:cat><c:val>%s</c:val><c:smooth val="0"/></c:ser>' % [colour, cat_ref, val_ref]
		idx += 1
	var xa := '<c:title>%s</c:title>' % _rich(str(c.get("x_title", "")), 1000) if str(c.get("x_title", "")) != "" else ""
	var ya := '<c:title>%s</c:title>' % _rich(str(c.get("y_title", "")), 1000) if str(c.get("y_title", "")) != "" else ""
	match kind:
		"bar":
			s += '<c:barChart><c:barDir val="%s"/><c:grouping val="clustered"/><c:varyColors val="0"/>%s<c:gapWidth val="80"/><c:axId val="1001"/><c:axId val="1002"/></c:barChart>' % ["bar" if bool(c.get("horizontal", false)) else "col", sers]
			s += '<c:catAx><c:axId val="1001"/><c:scaling><c:orientation val="%s"/></c:scaling><c:delete val="0"/><c:axPos val="%s"/>%s<c:numFmt formatCode="General" sourceLinked="0"/><c:tickLblPos val="nextTo"/><c:crossAx val="1002"/><c:crosses val="autoZero"/><c:auto val="1"/><c:lblAlgn val="ctr"/><c:lblOffset val="100"/><c:noMultiLvlLbl val="0"/></c:catAx>' % ["maxMin" if bool(c.get("horizontal", false)) else "minMax", "l" if bool(c.get("horizontal", false)) else "b", xa]
			s += '<c:valAx><c:axId val="1002"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="%s"/><c:majorGridlines/>%s<c:numFmt formatCode="General" sourceLinked="0"/><c:tickLblPos val="nextTo"/><c:crossAx val="1001"/><c:crosses val="autoZero"/><c:crossBetween val="between"/></c:valAx>' % ["b" if bool(c.get("horizontal", false)) else "l", ya]
		"scatter":
			s += '<c:scatterChart><c:scatterStyle val="lineMarker"/><c:varyColors val="0"/>%s<c:axId val="1001"/><c:axId val="1002"/></c:scatterChart>' % sers
			s += '<c:valAx><c:axId val="1001"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="b"/>%s<c:numFmt formatCode="General" sourceLinked="0"/><c:tickLblPos val="nextTo"/><c:crossAx val="1002"/><c:crosses val="autoZero"/><c:crossBetween val="midCat"/></c:valAx>' % xa
			s += '<c:valAx><c:axId val="1002"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="l"/><c:majorGridlines/>%s<c:numFmt formatCode="General" sourceLinked="0"/><c:tickLblPos val="nextTo"/><c:crossAx val="1001"/><c:crosses val="autoZero"/><c:crossBetween val="midCat"/></c:valAx>' % ya
		_:
			s += '<c:lineChart><c:grouping val="standard"/><c:varyColors val="0"/>%s<c:marker val="1"/><c:axId val="1001"/><c:axId val="1002"/></c:lineChart>' % sers
			var skip := maxi(1, (r1 - r0 + 1) / 12)
			s += '<c:catAx><c:axId val="1001"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="b"/>%s<c:numFmt formatCode="General" sourceLinked="1"/><c:tickLblPos val="nextTo"/><c:crossAx val="1002"/><c:crosses val="autoZero"/><c:auto val="1"/><c:lblAlgn val="ctr"/><c:lblOffset val="100"/><c:tickLblSkip val="%d"/><c:tickMarkSkip val="%d"/><c:noMultiLvlLbl val="0"/></c:catAx>' % [xa, skip, skip]
			s += '<c:valAx><c:axId val="1002"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="l"/><c:majorGridlines/>%s<c:numFmt formatCode="General" sourceLinked="1"/><c:tickLblPos val="nextTo"/><c:crossAx val="1001"/><c:crosses val="autoZero"/><c:crossBetween val="between"/></c:valAx>' % ya
	s += '</c:plotArea><c:legend><c:legendPos val="b"/><c:overlay val="0"/></c:legend><c:plotVisOnly val="1"/><c:dispBlanksAs val="gap"/></c:chart></c:chartSpace>'
	return s
