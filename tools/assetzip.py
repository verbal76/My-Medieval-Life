"""Read files straight out of the asset archives without extracting them."""
import io
import posixpath
import zipfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent


class AssetZip:
    def __init__(self, name, root=""):
        self.zip = zipfile.ZipFile(REPO / name)
        self.root = root.strip("/")

    def _path(self, rel):
        p = posixpath.normpath(posixpath.join(self.root, rel)) if self.root else rel
        return p

    def read(self, rel):
        return self.zip.read(self._path(rel))

    def text(self, rel):
        return self.read(rel).decode("utf-8")

    def image(self, rel):
        return Image.open(io.BytesIO(self.read(rel))).convert("RGBA")
