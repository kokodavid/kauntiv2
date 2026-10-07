"""Resolve reusable Wikimedia Commons image metadata for candidate staging."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from html import unescape
from html.parser import HTMLParser
from urllib.parse import unquote, urlencode, urlparse
from urllib.request import Request, urlopen

COMMONS_API = 'https://commons.wikimedia.org/w/api.php'
USER_AGENT = 'Kaunti47WikidataCollector/1.0 (contact: support@kaunti47.com)'
ALLOWED_LICENCES = ('cc0', 'public domain', 'cc by', 'cc-by', 'cc by-sa', 'cc-by-sa')


class PlainText(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        self.parts.append(data)

    def value(self) -> str:
        return ' '.join(''.join(self.parts).split())


@dataclass(frozen=True)
class CommonsImage:
    key: str
    remote_url: str
    source_url: str
    licence: str
    licence_url: str | None
    attribution: str
    width: int | None
    height: int | None


def text(value: object) -> str:
    parser = PlainText()
    parser.feed(unescape(value if isinstance(value, str) else ''))
    return parser.value()


def file_title(file_url: str) -> str | None:
    parsed = urlparse(file_url)
    if parsed.hostname != 'commons.wikimedia.org' or not parsed.path.startswith('/wiki/Special:FilePath/'):
        return None
    filename = unquote(parsed.path.removeprefix('/wiki/Special:FilePath/')).strip()
    return f'File:{filename}' if filename else None


def is_allowed_licence(value: str) -> bool:
    normalized = value.casefold()
    return any(marker in normalized for marker in ALLOWED_LICENCES)


def resolve(file_url: str) -> CommonsImage | None:
    title = file_title(file_url)
    if not title:
        return None
    params = {
        'action': 'query',
        'format': 'json',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|size',
        'iiurlwidth': 1600,
        'titles': title,
    }
    query = f'{COMMONS_API}?{urlencode(params)}'
    request = Request(query, headers={'user-agent': USER_AGENT})
    with urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode('utf-8'))
    pages = payload.get('query', {}).get('pages', {})
    page = next(iter(pages.values()), {}) if isinstance(pages, dict) else {}
    info = page.get('imageinfo', [None])[0] if isinstance(page, dict) else None
    if not isinstance(info, dict):
        return None
    metadata = info.get('extmetadata', {})
    if not isinstance(metadata, dict):
        return None
    licence = text(metadata.get('LicenseShortName', {}).get('value'))
    attribution = text(metadata.get('Artist', {}).get('value')) or text(metadata.get('Credit', {}).get('value'))
    remote_url = info.get('thumburl') or info.get('url')
    source_url = info.get('descriptionurl')
    if not isinstance(remote_url, str) or not isinstance(source_url, str) or not attribution or not is_allowed_licence(licence):
        return None
    parsed_remote = urlparse(remote_url)
    if parsed_remote.scheme != 'https' or parsed_remote.hostname != 'upload.wikimedia.org':
        return None
    licence_url = text(metadata.get('LicenseUrl', {}).get('value')) or None
    return CommonsImage(
        key=title,
        remote_url=remote_url,
        source_url=source_url,
        licence=licence,
        licence_url=licence_url,
        attribution=attribution,
        width=info.get('thumbwidth') if isinstance(info.get('thumbwidth'), int) else None,
        height=info.get('thumbheight') if isinstance(info.get('thumbheight'), int) else None,
    )
