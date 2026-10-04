// Re-encodes a user photo so nothing but pixels survives: orientation is baked
// in, then EXIF, GPS, XMP, IPTC, ICC and every other profile are dropped, and
// the longest side is capped. EXIF removal does not hide faces, number plates
// or addresses visible in the picture; moderators review the pixels.
//
// CPU budget: an Edge Function request gets 2 s of CPU. In this WASM build a
// resize costs about 1.5 s even for a small image, and a full-size decode of a
// 12 MP photo costs about 2 s, which was measured to exceed the limit on a real
// project. JPEG can instead be decoded at 1/2, 1/4 or 1/8 scale directly, so we
// pick the smallest reduction that lands under MAX_SIDE and never resize.
// That takes 12 MP from about 2.2 s to about 0.5 s and 50 MP from about 6.9 s
// to about 0.7 s.
import {
  AlphaOption,
  ImageMagick,
  initializeImageMagick,
  MagickColors,
  MagickFormat,
  MagickImageInfo,
  MagickReadSettings,
  type IMagickImageInfo,
} from "@imagemagick/magick-wasm";

export const MAX_SIDE = 2560;
export const MAX_SOURCE_BYTES = 16_000_000;
export const MAX_SOURCE_PIXELS = 52_000_000;
const QUALITY = 82;

/** The photo itself is unusable; retrying will not help. */
export class PhotoRejected extends Error {}

export interface SanitizedPhoto {
  bytes: Uint8Array;
  width: number;
  height: number;
}

let ready: Promise<void> | undefined;
function init(): Promise<void> {
  ready ??= (async () => {
    const wasm = await Deno.readFile(
      new URL("magick.wasm", import.meta.resolve("@imagemagick/magick-wasm")),
    );
    await initializeImageMagick(wasm);
  })();
  return ready;
}

export async function sanitizePhoto(source: Uint8Array): Promise<SanitizedPhoto> {
  await init();
  if (source.length > MAX_SOURCE_BYTES) {
    throw new PhotoRejected("Photo is too large to publish");
  }
  let info: IMagickImageInfo;
  try {
    // Reads the header only, so oversized dimensions are caught before decoding.
    info = MagickImageInfo.create(source);
  } catch {
    throw new PhotoRejected("Unsupported photo format");
  }
  const format = info.format;
  const isJpeg = format === MagickFormat.Jpeg || format === MagickFormat.Jpg;
  if (!isJpeg && format !== MagickFormat.Png && format !== MagickFormat.WebP) {
    throw new PhotoRejected("Unsupported photo format");
  }
  if (info.width * info.height > MAX_SOURCE_PIXELS) {
    throw new PhotoRejected("Photo is too large to publish");
  }

  const longest = Math.max(info.width, info.height);
  // Smallest JPEG decode scale (1, 2, 4 or 8) that fits under MAX_SIDE.
  let scale = 1;
  while (longest / scale > MAX_SIDE && scale < 8) scale *= 2;
  // The app only ever uploads JPEG. Other formats cannot be decoded at reduced
  // scale, and resizing them would exceed the CPU budget, so only small ones pass.
  if ((!isJpeg && scale > 1) || longest / scale > MAX_SIDE) {
    throw new PhotoRejected("Photo is too large to publish");
  }

  const settings = new MagickReadSettings();
  if (isJpeg && scale > 1) {
    // The decoder keeps both sides at or above this size, so give it the real
    // width and height divided by the scale, not a square.
    settings.setDefine(
      MagickFormat.Jpeg,
      "size",
      `${Math.ceil(info.width / scale)}x${Math.ceil(info.height / scale)}`,
    );
  }
  try {
    return ImageMagick.read(source, settings, (image) => {
      image.autoOrient();
      if (image.hasAlpha) {
        image.backgroundColor = MagickColors.White;
        image.alpha(AlphaOption.Remove);
      }
      image.strip();
      image.quality = QUALITY;
      const width = image.width;
      const height = image.height;
      return image.write(MagickFormat.Jpeg, (out) => ({ bytes: new Uint8Array(out), width, height }));
    });
  } catch {
    throw new PhotoRejected("Photo could not be read");
  }
}
