<?php
/**
 * Copilot_20260618_205451.png → ic_stat_onesignal_default (silueta blanca, fondo transparente).
 */
$srcPath = __DIR__ . '/../../../../mesa_de_trabajo/obs_logo_antiguo/Copilot_20260618_205451.png';
$resBase = __DIR__ . '/../app/src/main/res';
$previewDir = __DIR__ . '/../../../../mesa_de_trabajo/obs_logo_antiguo';

/** Recorte al centro: elimina el anillo circular exterior y agranda la Z en iconos pequeños. */
$focusCenterRatio = 0.56;
/** Margen mínimo dentro del drawable (Android recomienda algo de padding). */
$marginRatio = 0.02;

$sizes = [
    'mdpi' => 24,
    'hdpi' => 36,
    'xhdpi' => 48,
    'xxhdpi' => 72,
    'xxxhdpi' => 96,
];

if (!file_exists($srcPath)) {
    fwrite(STDERR, "No encontrado: $srcPath\n");
    exit(1);
}

$src = imagecreatefrompng($srcPath);
imagesavealpha($src, true);
$w = imagesx($src);
$h = imagesy($src);
echo "Origen: {$w}x{$h}\n";

/** Píxeles blancos del logo (fondo transparente). */
function isLogoPixel(int $r, int $g, int $b, int $a, int $x, int $y, int $w, int $h): bool
{
    if ($a >= 110) {
        return false;
    }
    $lum = 0.299 * $r + 0.587 * $g + 0.114 * $b;
    return $lum >= 180;
}

function cropCenter(GdImage $img, float $ratio): GdImage
{
    $w = imagesx($img);
    $h = imagesy($img);
    $cw = max(1, (int) floor($w * $ratio));
    $ch = max(1, (int) floor($h * $ratio));
    $ox = (int) floor(($w - $cw) / 2);
    $oy = (int) floor(($h - $ch) / 2);

    $dst = imagecreatetruecolor($cw, $ch);
    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    $transparent = imagecolorallocatealpha($dst, 0, 0, 0, 127);
    imagefill($dst, 0, 0, $transparent);
    imagecopy($dst, $img, 0, 0, $ox, $oy, $cw, $ch);
    return $dst;
}

function squareIcon(GdImage $content, int $outSize, float $marginRatio = 0.02): GdImage
{
    $cw = imagesx($content);
    $ch = imagesy($content);
    $transparent = imagecolorallocatealpha($content, 0, 0, 0, 127);

    $dst = imagecreatetruecolor($outSize, $outSize);
    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    imagefill($dst, 0, 0, $transparent);

    $inner = (int) floor($outSize * (1 - 2 * $marginRatio));
    $scale = min($inner / $cw, $inner / $ch);
    $nw = max(1, (int) floor($cw * $scale));
    $nh = max(1, (int) floor($ch * $scale));
    $ox = (int) floor(($outSize - $nw) / 2);
    $oy = (int) floor(($outSize - $nh) / 2);

    imagealphablending($dst, true);
    imagecopyresampled($dst, $content, $ox, $oy, 0, 0, $nw, $nh, $cw, $ch);
    imagesavealpha($dst, true);
    return $dst;
}

function saveOnBackground(GdImage $icon, string $path, int $br, int $bg, int $bb): void
{
    $w = imagesx($icon);
    $h = imagesy($icon);
    $bgImg = imagecreatetruecolor($w, $h);
    $c = imagecolorallocate($bgImg, $br, $bg, $bb);
    imagefill($bgImg, 0, 0, $c);
    imagealphablending($bgImg, true);
    for ($y = 0; $y < $h; $y++) {
        for ($x = 0; $x < $w; $x++) {
            $rgba = imagecolorat($icon, $x, $y);
            $a = ($rgba >> 24) & 0x7F;
            if ($a >= 110) {
                continue;
            }
            $r = ($rgba >> 16) & 0xFF;
            $g = ($rgba >> 8) & 0xFF;
            $b = $rgba & 0xFF;
            $col = imagecolorallocate($bgImg, $r, $g, $b);
            imagesetpixel($bgImg, $x, $y, $col);
        }
    }
    imagepng($bgImg, $path);
    imagedestroy($bgImg);
}

// Extraer solo logo → canvas transparente con silueta blanca
$minX = $w;
$minY = $h;
$maxX = 0;
$maxY = 0;

for ($y = 0; $y < $h; $y++) {
    for ($x = 0; $x < $w; $x++) {
        $rgba = imagecolorat($src, $x, $y);
        $a = ($rgba >> 24) & 0x7F;
        $r = ($rgba >> 16) & 0xFF;
        $g = ($rgba >> 8) & 0xFF;
        $b = $rgba & 0xFF;
        if (isLogoPixel($r, $g, $b, $a, $x, $y, $w, $h)) {
            $minX = min($minX, $x);
            $minY = min($minY, $y);
            $maxX = max($maxX, $x);
            $maxY = max($maxY, $y);
        }
    }
}

if ($maxX <= $minX) {
    fwrite(STDERR, "No se detectó logo en la imagen.\n");
    exit(1);
}

$contentW = $maxX - $minX + 1;
$contentH = $maxY - $minY + 1;
echo "Logo detectado: {$contentW}x{$contentH}\n";

$content = imagecreatetruecolor($contentW, $contentH);
imagealphablending($content, false);
imagesavealpha($content, true);
$transparent = imagecolorallocatealpha($content, 0, 0, 0, 127);
$white = imagecolorallocatealpha($content, 255, 255, 255, 0);
imagefill($content, 0, 0, $transparent);

for ($y = 0; $y < $contentH; $y++) {
    for ($x = 0; $x < $contentW; $x++) {
        $sx = $minX + $x;
        $sy = $minY + $y;
        $rgba = imagecolorat($src, $sx, $sy);
        $a = ($rgba >> 24) & 0x7F;
        $r = ($rgba >> 16) & 0xFF;
        $g = ($rgba >> 8) & 0xFF;
        $b = $rgba & 0xFF;
        if (isLogoPixel($r, $g, $b, $a, $sx, $sy, $w, $h)) {
            imagesetpixel($content, $x, $y, $white);
        }
    }
}
imagedestroy($src);

$contentFocused = cropCenter($content, $focusCenterRatio);
imagedestroy($content);
$content = $contentFocused;
echo "Recorte centro {$focusCenterRatio}: " . imagesx($content) . 'x' . imagesy($content) . " (margen {$marginRatio})\n";

$icon512 = squareIcon($content, 512, $marginRatio);
imagepng($icon512, $previewDir . '/ic_stat_onesignal_preview_512.png');
saveOnBackground($icon512, $previewDir . '/ic_stat_onesignal_preview_FONDO_OSCURO.png', 0x1a, 0x1a, 0x1a);
saveOnBackground($icon512, $previewDir . '/ic_stat_onesignal_preview_FONDO_TURQUESA.png', 0x18, 0xE8, 0xBC);
echo "Preview: {$previewDir}/ic_stat_onesignal_preview_FONDO_OSCURO.png\n";
imagedestroy($icon512);

foreach ($sizes as $folder => $size) {
    $icon = squareIcon($content, $size, $marginRatio);
    $dir = $resBase . '/drawable-' . $folder;
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
    imagepng($icon, $dir . '/ic_stat_onesignal_default.png');
    imagedestroy($icon);
    echo "OK drawable-{$folder}/ic_stat_onesignal_default.png ({$size}px)\n";
}

imagedestroy($content);
echo "Listo.\n";
