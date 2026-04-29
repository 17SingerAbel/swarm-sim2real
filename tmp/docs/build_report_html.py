from __future__ import annotations

import base64
import html as html_lib
import mimetypes
import re
from difflib import SequenceMatcher
from pathlib import Path

from lxml import etree, html


ORIGINAL_HTML = Path(r"C:/Users/abel/Desktop/MIE8888/mie8888/tmp/docs/word_html_test/original.html")
REVISED_HTML = Path(r"C:/Users/abel/Desktop/MIE8888/mie8888/tmp/docs/word_html_revised/revised.html")
OUTPUT_DIR = Path(r"C:/Users/abel/Desktop/MIE8888/mie8888/output/doc")
OUTPUT_CLEAN = OUTPUT_DIR / "revised_report_clean.html"
OUTPUT_HIGHLIGHT = OUTPUT_DIR / "revised_report_highlighted.html"


SUMMARY_HTML = """
<div class="codex-summary">
  <h2>Codex Change Summary</h2>
  <ul>
    <li>The old synchronous versus asynchronous distinction has been removed.</li>
    <li>Conflict is now defined as one normal DES interceptor assignment conflict during the three-step broadcast, bidding, and selection process.</li>
    <li>Joint global assignment is described as a joint reassignment across the affected targets when they compete for the same candidate sensors.</li>
    <li>Terminology has been shifted toward global assignment method and joint reassignment naming throughout the report.</li>
  </ul>
</div>
"""


STYLE_HTML = """
<style>
.codex-summary {
  background: #fff6bf;
  border: 1px solid #d7c55f;
  padding: 18px 22px;
  margin: 20px auto 24px;
  max-width: 840px;
  line-height: 1.45;
}
.codex-summary h2 {
  margin: 0 0 10px;
  font-size: 18px;
}
.codex-summary ul {
  margin: 0;
  padding-left: 20px;
}
.codex-summary li {
  margin: 4px 0;
}
.codex-change {
  background: #fff59d;
}
</style>
"""


def parse_html(path: Path):
    return html.fromstring(path.read_text(encoding="utf-8", errors="ignore"))


def normalized_text(element) -> str:
    return " ".join("".join(element.itertext()).split())


def text_elements(doc):
    elements = doc.xpath(
        "//body//*[self::p or self::h1 or self::h2 or self::h3]"
        "[not(ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' codex-summary ')])]"
    )
    return [element for element in elements if normalized_text(element)]


def inject_style(doc) -> None:
    head_nodes = doc.xpath("//head")
    if not head_nodes:
        return
    head = head_nodes[0]
    head.append(html.fragment_fromstring(STYLE_HTML, create_parent=False))


def inject_summary(doc) -> None:
    body_nodes = doc.xpath("//body")
    if not body_nodes:
        return
    body = body_nodes[0]
    body.insert(0, html.fragment_fromstring(SUMMARY_HTML, create_parent=False))


def inline_assets(doc, source_html: Path) -> None:
    for link in doc.xpath("//link[contains(@href, '.files/')]"):
        parent = link.getparent()
        if parent is not None:
            parent.remove(link)

    base_dir = source_html.parent
    for node in doc.xpath("//*[@src]"):
        src = node.get("src")
        if not src or src.startswith("data:") or re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", src):
            continue
        asset_path = (base_dir / src).resolve()
        if not asset_path.exists() or not asset_path.is_file():
            continue
        mime_type = mimetypes.guess_type(asset_path.name)[0] or "application/octet-stream"
        encoded = base64.b64encode(asset_path.read_bytes()).decode("ascii")
        node.set("src", f"data:{mime_type};base64,{encoded}")


def tokenize(text: str):
    return re.findall(r"\s+|[A-Za-z0-9_]+|[^A-Za-z0-9_\s]+", text)


def build_highlight_markup(old_text: str, new_text: str) -> str:
    old_tokens = tokenize(old_text)
    new_tokens = tokenize(new_text)
    matcher = SequenceMatcher(a=old_tokens, b=new_tokens)
    parts = []
    for tag, _i1, _i2, j1, j2 in matcher.get_opcodes():
        chunk = "".join(new_tokens[j1:j2])
        escaped = html_lib.escape(chunk)
        if not chunk:
            continue
        if tag == "equal":
            parts.append(escaped)
        else:
            parts.append(f'<span class="codex-change">{escaped}</span>')
    return "".join(parts)


def replace_element_content(element, markup: str) -> None:
    for child in list(element):
        element.remove(child)
    element.text = None

    fragments = html.fragments_fromstring(markup)
    last_child = None
    for fragment in fragments:
        if isinstance(fragment, str):
            if last_child is None:
                element.text = (element.text or "") + fragment
            else:
                last_child.tail = (last_child.tail or "") + fragment
        else:
            element.append(fragment)
            last_child = fragment


def build_outputs() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    original_doc = parse_html(ORIGINAL_HTML)
    revised_clean_doc = parse_html(REVISED_HTML)
    revised_highlight_doc = parse_html(REVISED_HTML)

    inject_style(revised_clean_doc)
    inject_style(revised_highlight_doc)
    inject_summary(revised_clean_doc)
    inject_summary(revised_highlight_doc)

    inline_assets(revised_clean_doc, REVISED_HTML)
    inline_assets(revised_highlight_doc, REVISED_HTML)

    original_text_nodes = text_elements(original_doc)
    revised_text_nodes = text_elements(revised_highlight_doc)

    if len(original_text_nodes) != len(revised_text_nodes):
        raise RuntimeError(
            f"Text node count mismatch: original={len(original_text_nodes)} revised={len(revised_text_nodes)}"
        )

    changed_nodes = 0
    for original_node, revised_node in zip(original_text_nodes, revised_text_nodes):
        old_text = normalized_text(original_node)
        new_text = normalized_text(revised_node)
        if old_text == new_text:
            continue
        replace_element_content(revised_node, build_highlight_markup(old_text, new_text))
        changed_nodes += 1

    OUTPUT_CLEAN.write_text(
        etree.tostring(revised_clean_doc, encoding="unicode", method="html"),
        encoding="utf-8",
    )
    OUTPUT_HIGHLIGHT.write_text(
        etree.tostring(revised_highlight_doc, encoding="unicode", method="html"),
        encoding="utf-8",
    )

    print(OUTPUT_CLEAN)
    print(OUTPUT_HIGHLIGHT)
    print(f"changed_html_nodes={changed_nodes}")


if __name__ == "__main__":
    build_outputs()
