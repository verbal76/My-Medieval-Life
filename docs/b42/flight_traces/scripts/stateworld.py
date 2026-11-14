"""The world save inside a flight-recorder segment state file (economy_sim --state: var_to_str with a JSON "world" string)."""
import json,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import gcpf
def world(path):
    s=gcpf.read(path).decode('utf-8')
    i=s.index('"world": "')+len('"world": ')
    ws,_=json.JSONDecoder().raw_decode(s,i)
    return json.loads(ws)
