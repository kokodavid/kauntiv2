// Run: deno test --allow-read sanitize_test.ts   (from this folder)
import assert from "node:assert/strict";
import { ImageMagick, MagickColors, MagickFormat } from "@imagemagick/magick-wasm";
import { MAX_SIDE, PhotoRejected, sanitizePhoto } from "./sanitize.ts";

const fixture = (name: string) => Deno.readFile(new URL(`./fixtures/${name}`, import.meta.url));

/** Names the JPEG segments before the image data starts. */
function segments(bytes: Uint8Array): string[] {
  assert.deepEqual([bytes[0], bytes[1]], [0xff, 0xd8], "output is a JPEG");
  const found: string[] = [];
  let i = 2;
  while (i < bytes.length && bytes[i] === 0xff) {
    const marker = bytes[i + 1];
    if (marker === 0xda) break;
    found.push(marker.toString(16));
    i += 2 + ((bytes[i + 2] << 8) | bytes[i + 3]);
  }
  return found;
}

// APP1 (EXIF/XMP), APP2 (ICC), APP13 (IPTC), APP14 and comments must all be gone.
const FORBIDDEN = ["e1", "e2", "e3", "ed", "ee", "fe"];

function assertClean(bytes: Uint8Array) {
  const present = segments(bytes).filter((m) => FORBIDDEN.includes(m));
  assert.deepEqual(present, [], `unexpected metadata segments: ${present}`);
  const text = new TextDecoder("latin1").decode(bytes);
  for (const needle of ["Exif", "FixtureCam", "Model Test", "ns.adobe.com", "GPS"]) {
    assert.ok(!text.includes(needle), `output still contains ${needle}`);
  }
}

Deno.test("strips GPS and device metadata and bakes in the rotation", async () => {
  const out = await sanitizePhoto(await fixture("gps_rotated.jpg"));
  assertClean(out.bytes);
  // The source is 1600x1200 with an orientation tag; the pixels now stand upright.
  assert.deepEqual([out.width, out.height], [1200, 1600]);
});

Deno.test("decodes large photos at reduced scale, upright and without metadata", async () => {
  const out = await sanitizePhoto(await fixture("large_gps.jpg"));
  assertClean(out.bytes);
  // 4200x3150 with an orientation tag is read at 1/2 scale and rotated upright.
  assert.deepEqual([out.width, out.height], [1575, 2100]);
  assert.ok(Math.max(out.width, out.height) <= MAX_SIDE);
});

// Generated in memory so no huge file is committed.
function solidJpeg(width: number, height: number): Uint8Array {
  return ImageMagick.read(MagickColors.SteelBlue, width, height, (image) =>
    image.write(MagickFormat.Jpeg, (data) => new Uint8Array(data)));
}

Deno.test("a 48 MP photo is reduced without resizing and stays under the cap", async () => {
  const out = await sanitizePhoto(solidJpeg(8000, 6000));
  assertClean(out.bytes);
  assert.deepEqual([out.width, out.height], [2000, 1500]); // 1/4 scale
});

Deno.test("rejects photos above the pixel cap before decoding", async () => {
  await assert.rejects(
    async () => await sanitizePhoto(solidJpeg(9000, 6000)),
    (e: unknown) => e instanceof PhotoRejected && e.message.includes("too large"),
  );
});

Deno.test("flattens transparency and outputs JPEG", async () => {
  const out = await sanitizePhoto(await fixture("alpha.png"));
  assertClean(out.bytes);
  assert.deepEqual([out.width, out.height], [400, 300]);
});

Deno.test("rejects enormous dimensions before decoding", async () => {
  await assert.rejects(async () => await sanitizePhoto(await fixture("huge_dimensions.png")), (e: unknown) => e instanceof PhotoRejected && e.message.includes("too large"));
});

Deno.test("rejects files that are not images", async () => {
  await assert.rejects(async () => await sanitizePhoto(await fixture("not_an_image.jpg")), (e: unknown) => e instanceof PhotoRejected && e.message.includes("Unsupported"));
});

Deno.test("rejects oversized files by byte count", async () => {
  await assert.rejects(async () => await sanitizePhoto(new Uint8Array(16_000_001)), (e: unknown) => e instanceof PhotoRejected && e.message.includes("too large"));
});
