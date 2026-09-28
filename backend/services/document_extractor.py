# backend/services/document_extractor.py

"""
Service d'extraction de texte a partir de documents de cours
Supporte : PDF (.pdf), Word (.docx), Texte (.txt), Markdown (.md).
"""

import io
import xml.etree.ElementTree as ET
import zipfile
from pypdf import PdfReader


def extract_text_from_file(file_bytes: bytes, filename: str) -> str:
    lower_name = filename.lower()

    # 1. Fichiers texte brut et Markdown
    if lower_name.endswith((".txt", ".md")):
        return file_bytes.decode("utf-8", errors="replace").strip()

    # 2. Documents Word (.docx) : extraction XML native sans dependance lourde
    if lower_name.endswith(".docx"):
        try:
            with zipfile.ZipFile(io.BytesIO(file_bytes)) as docx_zip:
                xml_content = docx_zip.read("word/document.xml")
                tree = ET.fromstring(xml_content)
                paragraphs = []
                for node in tree.iter("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p"):
                    text = "".join(node.itertext()).strip()
                    if text:
                        paragraphs.append(text)
                return "\n\n".join(paragraphs)
        except Exception as e:
            raise ValueError(f"Impossible de lire le document Word (.docx) : {e}")

    # 3. Documents PDF (.pdf)
    if lower_name.endswith(".pdf"):
        try:
            reader = PdfReader(io.BytesIO(file_bytes))
            pages_text = []
            for page in reader.pages:
                txt = page.extract_text() or ""
                if txt.strip():
                    pages_text.append(txt.strip())
            return "\n\n".join(pages_text)
        except Exception as e:
            raise ValueError(f"Impossible d'extraire le texte du PDF : {e}")

    raise ValueError(
        f"Format non pris en charge ({filename}). Formats acceptés : .pdf, .docx, .txt, .md"
    )