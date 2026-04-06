#!/usr/bin/env python3

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
METADATA_DIR = ROOT / "metadata"
REPORTS_DIR = ROOT / "reports"
ALL_SIZES = ("32", "48", "64", "128", "256", "512")

ISO_REGION_LABELS_TSV = """
ad\tAndorra
ae\tUnited Arab Emirates
af\tAfghanistan
ag\tAntigua & Barbuda
ai\tAnguilla
al\tAlbania
am\tArmenia
ao\tAngola
ar\tArgentina
as\tAmerican Samoa
at\tAustria
au\tAustralia
aw\tAruba
ax\tAland Islands
az\tAzerbaijan
ba\tBosnia & Herzegovina
bb\tBarbados
bd\tBangladesh
be\tBelgium
bf\tBurkina Faso
bg\tBulgaria
bh\tBahrain
bi\tBurundi
bj\tBenin
bl\tSt. Barthelemy
bm\tBermuda
bn\tBrunei
bo\tBolivia
bq\tCaribbean Netherlands
br\tBrazil
bs\tBahamas
bt\tBhutan
bv\tBouvet Island
bw\tBotswana
by\tBelarus
bz\tBelize
ca\tCanada
cc\tCocos (Keeling) Islands
cd\tCongo - Kinshasa
cf\tCentral African Republic
cg\tCongo - Brazzaville
ch\tSwitzerland
ci\tCote d'Ivoire
ck\tCook Islands
cl\tChile
cm\tCameroon
cn\tChina
co\tColombia
cr\tCosta Rica
cu\tCuba
cv\tCape Verde
cw\tCuracao
cx\tChristmas Island
cy\tCyprus
cz\tCzechia
de\tGermany
dg\tDiego Garcia
dj\tDjibouti
dk\tDenmark
dm\tDominica
do\tDominican Republic
dz\tAlgeria
ea\tCeuta & Melilla
ec\tEcuador
ee\tEstonia
eg\tEgypt
eh\tWestern Sahara
er\tEritrea
es\tSpain
et\tEthiopia
eu\tEuropean Union
fi\tFinland
fj\tFiji
fk\tFalkland Islands
fm\tMicronesia
fo\tFaroe Islands
fr\tFrance
ga\tGabon
gb\tUnited Kingdom
gd\tGrenada
ge\tGeorgia
gf\tFrench Guiana
gg\tGuernsey
gh\tGhana
gi\tGibraltar
gl\tGreenland
gm\tGambia
gn\tGuinea
gp\tGuadeloupe
gq\tEquatorial Guinea
gr\tGreece
gs\tSouth Georgia & South Sandwich Islands
gt\tGuatemala
gu\tGuam
gw\tGuinea-Bissau
gy\tGuyana
hk\tHong Kong SAR China
hm\tHeard & McDonald Islands
hn\tHonduras
hr\tCroatia
ht\tHaiti
hu\tHungary
ic\tCanary Islands
id\tIndonesia
ie\tIreland
il\tIsrael
im\tIsle of Man
in\tIndia
io\tBritish Indian Ocean Territory
iq\tIraq
ir\tIran
is\tIceland
it\tItaly
je\tJersey
jm\tJamaica
jo\tJordan
jp\tJapan
ke\tKenya
kg\tKyrgyzstan
kh\tCambodia
ki\tKiribati
km\tComoros
kn\tSt. Kitts & Nevis
kp\tNorth Korea
kr\tSouth Korea
kw\tKuwait
ky\tCayman Islands
kz\tKazakhstan
la\tLaos
lb\tLebanon
lc\tSt. Lucia
li\tLiechtenstein
lk\tSri Lanka
lr\tLiberia
ls\tLesotho
lt\tLithuania
lu\tLuxembourg
lv\tLatvia
ly\tLibya
ma\tMorocco
mc\tMonaco
md\tMoldova
me\tMontenegro
mf\tSt. Martin
mg\tMadagascar
mh\tMarshall Islands
mk\tNorth Macedonia
ml\tMali
mm\tMyanmar (Burma)
mn\tMongolia
mo\tMacao SAR China
mp\tNorthern Mariana Islands
mq\tMartinique
mr\tMauritania
ms\tMontserrat
mt\tMalta
mu\tMauritius
mv\tMaldives
mw\tMalawi
mx\tMexico
my\tMalaysia
mz\tMozambique
na\tNamibia
ne\tNiger
nf\tNorfolk Island
ng\tNigeria
ni\tNicaragua
nl\tNetherlands
no\tNorway
np\tNepal
nr\tNauru
nu\tNiue
nz\tNew Zealand
om\tOman
pa\tPanama
pe\tPeru
pf\tFrench Polynesia
pg\tPapua New Guinea
ph\tPhilippines
pk\tPakistan
pl\tPoland
pm\tSt. Pierre & Miquelon
pn\tPitcairn Islands
pr\tPuerto Rico
ps\tPalestinian Territories
pt\tPortugal
pw\tPalau
py\tParaguay
qa\tQatar
re\tReunion
ro\tRomania
rs\tSerbia
ru\tRussia
rw\tRwanda
sa\tSaudi Arabia
sb\tSolomon Islands
sc\tSeychelles
sd\tSudan
se\tSweden
sg\tSingapore
sh\tSt. Helena
si\tSlovenia
sj\tSvalbard & Jan Mayen
sk\tSlovakia
sl\tSierra Leone
sm\tSan Marino
sn\tSenegal
so\tSomalia
sr\tSuriname
ss\tSouth Sudan
st\tSao Tome & Principe
sv\tEl Salvador
sx\tSint Maarten
sy\tSyria
sz\tEswatini
ta\tTristan da Cunha
tc\tTurks & Caicos Islands
td\tChad
tf\tFrench Southern Territories
tg\tTogo
th\tThailand
tj\tTajikistan
tk\tTokelau
tl\tTimor-Leste
tm\tTurkmenistan
tn\tTunisia
to\tTonga
tr\tTurkey
tt\tTrinidad & Tobago
tv\tTuvalu
tw\tTaiwan
tz\tTanzania
ua\tUkraine
ug\tUganda
um\tU.S. Outlying Islands
un\tUnited Nations
us\tUnited States
uy\tUruguay
uz\tUzbekistan
va\tVatican City
vc\tSt. Vincent & Grenadines
ve\tVenezuela
vg\tBritish Virgin Islands
vi\tU.S. Virgin Islands
vn\tVietnam
vu\tVanuatu
ws\tSamoa
xk\tKosovo
ye\tYemen
yt\tMayotte
za\tSouth Africa
zm\tZambia
zw\tZimbabwe
""".strip()


def parse_tsv_mapping(text: str) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for line in text.splitlines():
        code, label = line.split("\t", 1)
        mapping[code.strip()] = label.strip()
    return mapping


ISO_REGION_LABELS = parse_tsv_mapping(ISO_REGION_LABELS_TSV)

NON_COUNTRY_ICON_IDS = {
    "binancecoin",
    "bitcoin",
    "dogecoin",
    "ecowas",
    "ethereum",
    "eu",
    "gold",
    "imf",
    "ld",
    "litecoin",
    "nato",
    "oecs",
    "palladium",
    "platinum",
    "silver",
    "tether",
    "un",
    "xpf",
}


def load_mapping(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return {str(key): normalize_label(value) for key, value in data.items()}


def normalize_label(value: object) -> str:
    if value is None:
        return "-"
    text = str(value).strip()
    return text or "-"


def escape_md(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", "<br>")


def make_link(report_path: Path, target_path: Path, label: str = "view") -> str:
    relative_path = os.path.relpath(target_path, report_path.parent).replace(os.sep, "/")
    return f"[{escape_md(label)}]({relative_path})"


def make_table(headers: Iterable[str], rows: Iterable[Iterable[object]]) -> str:
    header_list = list(headers)
    lines = [
        "| " + " | ".join(escape_md(header) for header in header_list) + " |",
        "| " + " | ".join("---" for _ in header_list) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(escape_md(value) for value in row) + " |")
    return "\n".join(lines)


def scan_svg_ids(directory: Path) -> set[str]:
    if not directory.exists():
        return set()
    return {path.stem for path in directory.glob("*.svg")}


def scan_raster_ids(directory: Path, extension: str) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {size: set() for size in ALL_SIZES}
    if not directory.exists():
        return result
    for size in ALL_SIZES:
        size_dir = directory / size
        if not size_dir.exists():
            continue
        result[size] = {path.stem for path in size_dir.glob(f"*.{extension}")}
    return result


def union_ids(*collections: object) -> set[str]:
    result: set[str] = set()
    for collection in collections:
        if isinstance(collection, dict):
            for values in collection.values():
                result.update(values)
        else:
            result.update(collection)
    return result


def present_sizes(size_map: dict[str, set[str]], icon_id: str) -> list[str]:
    return [size for size in ALL_SIZES if icon_id in size_map.get(size, set())]


def summarize_sizes(sizes: Iterable[str]) -> str:
    values = list(sizes)
    if not values:
        return "-"
    if tuple(values) == ALL_SIZES:
        return "all"
    return ", ".join(values)


def total_raster_files(size_map: dict[str, set[str]]) -> int:
    return sum(len(icon_ids) for icon_ids in size_map.values())


def coverage_row(scope: str, format_name: str, size_map: dict[str, set[str]], total_icons: int) -> list[str]:
    return [scope, format_name, *[f"{len(size_map[size])}/{total_icons}" for size in ALL_SIZES]]


def resolve_currency_label(icon_id: str, overrides: dict[str, str]) -> str:
    if icon_id in overrides:
        return overrides[icon_id]
    return ISO_REGION_LABELS.get(icon_id, "-")


def resolve_provider_label(provider_id: str, overrides: dict[str, str]) -> str:
    return overrides.get(provider_id, "-")


def is_non_country_icon(icon_id: str) -> bool:
    return icon_id in NON_COUNTRY_ICON_IDS


def currency_inventory_row(report_path: Path, record: dict[str, object]) -> list[object]:
    return [
        record["id"],
        record["label"],
        make_link(report_path, record["canonical_svg"]) if record["canonical_svg"] else "-",
        make_link(report_path, record["legacy_svg"]) if record["legacy_svg"] else "-",
        summarize_sizes(record["canonical_png"]),
        summarize_sizes(record["canonical_webp"]),
        summarize_sizes(record["legacy_png"]),
        summarize_sizes(record["legacy_webp"]),
    ]


def version_sort_key(version: str) -> tuple[object, ...]:
    parts: list[object] = []
    for part in version.replace("-", ".").split("."):
        if part.isdigit():
            parts.append((0, int(part)))
        else:
            parts.append((1, part))
    return tuple(parts)


def build_currency_report(currency_overrides: dict[str, str]) -> str:
    report_path = REPORTS_DIR / "currencies-inventory.md"
    canonical_svg = ROOT / "currencies" / "svg"
    canonical_png = ROOT / "currencies" / "png"
    canonical_webp = ROOT / "currencies" / "webp"
    legacy_svg = ROOT / "svg"
    legacy_png = ROOT / "png"
    legacy_webp = ROOT / "webp"

    canonical_svg_ids = scan_svg_ids(canonical_svg)
    legacy_svg_ids = scan_svg_ids(legacy_svg)
    canonical_png_map = scan_raster_ids(canonical_png, "png")
    canonical_webp_map = scan_raster_ids(canonical_webp, "webp")
    legacy_png_map = scan_raster_ids(legacy_png, "png")
    legacy_webp_map = scan_raster_ids(legacy_webp, "webp")
    icon_ids = sorted(
        union_ids(
            canonical_svg_ids,
            legacy_svg_ids,
            canonical_png_map,
            canonical_webp_map,
            legacy_png_map,
            legacy_webp_map,
        )
    )

    records: list[dict[str, object]] = []
    for icon_id in icon_ids:
        label = resolve_currency_label(icon_id, currency_overrides)
        canonical_svg_path = canonical_svg / f"{icon_id}.svg"
        legacy_svg_path = legacy_svg / f"{icon_id}.svg"
        records.append(
            {
                "id": icon_id,
                "label": label,
                "canonical_svg": canonical_svg_path if canonical_svg_path.exists() else None,
                "legacy_svg": legacy_svg_path if legacy_svg_path.exists() else None,
                "canonical_png": present_sizes(canonical_png_map, icon_id),
                "canonical_webp": present_sizes(canonical_webp_map, icon_id),
                "legacy_png": present_sizes(legacy_png_map, icon_id),
                "legacy_webp": present_sizes(legacy_webp_map, icon_id),
            }
        )

    resolved_labels = sum(1 for record in records if record["label"] != "-")
    format_totals = [
        [
            "Canonical currencies",
            len(union_ids(canonical_svg_ids, canonical_png_map, canonical_webp_map)),
            len(canonical_svg_ids),
            total_raster_files(canonical_png_map),
            total_raster_files(canonical_webp_map),
            f"{resolved_labels}/{len(records)}",
        ],
        [
            "Legacy mirror",
            len(union_ids(legacy_svg_ids, legacy_png_map, legacy_webp_map)),
            len(legacy_svg_ids),
            total_raster_files(legacy_png_map),
            total_raster_files(legacy_webp_map),
            f"{resolved_labels}/{len(records)}",
        ],
    ]
    coverage = [
        coverage_row("Canonical currencies", "PNG", canonical_png_map, len(records)),
        coverage_row("Canonical currencies", "WebP", canonical_webp_map, len(records)),
        coverage_row("Legacy mirror", "PNG", legacy_png_map, len(records)),
        coverage_row("Legacy mirror", "WebP", legacy_webp_map, len(records)),
    ]
    geographic_records = [record for record in records if not is_non_country_icon(str(record["id"]))]
    non_country_records = [record for record in records if is_non_country_icon(str(record["id"]))]
    unresolved_rows = [[record["id"], record["label"]] for record in records if record["label"] == "-"]

    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    currency_labels_link = make_link(report_path, METADATA_DIR / "currency-labels.json", "metadata/currency-labels.json")

    parts = [
        "# Currency Icon Inventory",
        "",
        f"Generated at: {generated_at}",
        "",
        f"Labels are resolved from built-in ISO mappings plus overrides in {currency_labels_link}.",
        "Unknown or intentionally unresolved labels are shown as `-`.",
        "",
        "Legend: `all` = 32, 48, 64, 128, 256, 512.",
        "",
        "## Format Totals",
        "",
        make_table(
            ["Scope", "Icon IDs", "SVG icons", "PNG files", "WebP files", "Resolved labels"],
            format_totals,
        ),
        "",
        "## Size Coverage",
        "",
        make_table(["Scope", "Format", *ALL_SIZES], coverage),
        "",
        "## Inventory",
        "",
        "### Country, Territory, and Regional Icons",
        "",
        f"Grouped here: {len(geographic_records)}.",
        "",
        make_table(
            [
                "Code",
                "Label",
                "Canonical SVG",
                "Legacy SVG",
                "Canonical PNG",
                "Canonical WebP",
                "Legacy PNG",
                "Legacy WebP",
            ],
            [currency_inventory_row(report_path, record) for record in geographic_records],
        ),
        "",
        "### Non-Country Icons",
        "",
        "Crypto, commodities, organizations, and special currency icons are listed separately.",
        "Linden Dollar keeps the legacy slug `ld` in filenames.",
        "",
        make_table(
            [
                "Code",
                "Label",
                "Canonical SVG",
                "Legacy SVG",
                "Canonical PNG",
                "Canonical WebP",
                "Legacy PNG",
                "Legacy WebP",
            ],
            [currency_inventory_row(report_path, record) for record in non_country_records],
        ),
        "",
        "## Labels Needing Manual Fill",
        "",
    ]

    if unresolved_rows:
        parts.extend([make_table(["Code", "Current label"], unresolved_rows), ""])
    else:
        parts.extend(["All currency labels are resolved.", ""])

    return "\n".join(parts)


def build_provider_report(provider_overrides: dict[str, str]) -> str:
    report_path = REPORTS_DIR / "providers-inventory.md"
    manifest = json.loads((ROOT / "providers" / "index.json").read_text(encoding="utf-8"))
    versions = manifest.get("versions", {})
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    provider_labels_link = make_link(report_path, METADATA_DIR / "provider-labels.json", "metadata/provider-labels.json")

    summary_rows: list[list[object]] = []
    coverage_rows: list[list[str]] = []
    version_sections: list[str] = []

    for version in sorted(versions, key=version_sort_key):
        version_meta = versions[version]
        version_path = ROOT / version_meta["path"]
        index_path = ROOT / version_meta["index"]
        entries = json.loads(index_path.read_text(encoding="utf-8"))
        svg_ids = scan_svg_ids(version_path / "svg")
        png_map = scan_raster_ids(version_path / "png", "png")
        webp_map = scan_raster_ids(version_path / "webp", "webp")
        icon_ids = sorted(entries.keys())

        records: list[dict[str, object]] = []
        for provider_id in icon_ids:
            entry = entries.get(provider_id, {})
            slug = entry.get("name") or entry.get("files", {}).get("filename") or provider_id.lower()
            svg_path = version_path / "svg" / f"{slug}.svg"
            label = resolve_provider_label(provider_id, provider_overrides)
            records.append(
                {
                    "id": provider_id,
                    "slug": slug,
                    "label": label,
                    "svg": svg_path if svg_path.exists() else None,
                    "png": present_sizes(png_map, slug),
                    "webp": present_sizes(webp_map, slug),
                }
            )

        resolved_labels = sum(1 for record in records if record["label"] != "-")
        summary_rows.append(
            [
                version,
                len(records),
                len(svg_ids),
                total_raster_files(png_map),
                total_raster_files(webp_map),
                f"{resolved_labels}/{len(records)}",
            ]
        )
        coverage_rows.append(coverage_row(version, "PNG", png_map, len(records)))
        coverage_rows.append(coverage_row(version, "WebP", webp_map, len(records)))

        inventory_rows = [
            [
                record["id"],
                record["slug"],
                record["label"],
                make_link(report_path, record["svg"]) if record["svg"] else "-",
                summarize_sizes(record["png"]),
                summarize_sizes(record["webp"]),
            ]
            for record in records
        ]
        unresolved_rows = [[record["id"], record["slug"]] for record in records if record["label"] == "-"]

        section_parts = [
            f"## Version {version}",
            "",
            make_table(["ID", "Slug", "Label", "SVG", "PNG", "WebP"], inventory_rows),
            "",
            f"### Version {version} labels needing manual fill",
            "",
        ]
        if unresolved_rows:
            section_parts.extend([make_table(["ID", "Slug"], unresolved_rows), ""])
        else:
            section_parts.extend(["All provider labels are resolved for this version.", ""])

        version_sections.append("\n".join(section_parts))

    parts = [
        "# Provider Icon Inventory",
        "",
        f"Generated at: {generated_at}",
        "",
        f"Labels are resolved from {provider_labels_link}.",
        "Unknown or intentionally unresolved labels are shown as `-`.",
        "",
        "Legend: `all` = 32, 48, 64, 128, 256, 512.",
        "",
        "## Version Totals",
        "",
        make_table(
            ["Version", "Icon IDs", "SVG icons", "PNG files", "WebP files", "Resolved labels"],
            summary_rows,
        ),
        "",
        "## Size Coverage",
        "",
        make_table(["Version", "Format", *ALL_SIZES], coverage_rows),
        "",
        "\n".join(version_sections).strip(),
        "",
    ]
    return "\n".join(parts)


def main() -> int:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    currency_overrides = load_mapping(METADATA_DIR / "currency-labels.json")
    provider_overrides = load_mapping(METADATA_DIR / "provider-labels.json")

    (REPORTS_DIR / "currencies-inventory.md").write_text(build_currency_report(currency_overrides), encoding="utf-8")
    (REPORTS_DIR / "providers-inventory.md").write_text(build_provider_report(provider_overrides), encoding="utf-8")

    print("Generated reports:")
    print("- reports/currencies-inventory.md")
    print("- reports/providers-inventory.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())