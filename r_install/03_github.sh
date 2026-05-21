#!/bin/bash
#SBATCH --partition=interactive
#SBATCH --job-name=r_install_github
#SBATCH --output=r_install/logs/03_github_%j.out
#SBATCH --error=r_install/logs/03_github_%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4

R_BIN=/ref/rmlab/software/spack-1.1.0/opt/spack/linux-x86_64/r-4.5.2-jga4yt5sdbzfddqszotqf64bn5a6iu2m/bin
export PATH=$R_BIN:$PATH
export R_LIBS=/ref/rmlab/software/tyron/R-libs
export MAKEFLAGS="-j${SLURM_CPUS_PER_TASK:-4}"

# System libraries required for R package compilation (from spack)
SPACK=/ref/rmlab/software/spack-1.1.0/opt/spack/linux-x86_64
CMAKE_DIR=$SPACK/cmake-3.31.9-znxjxuyx64bqio4s3wc5izrggrpljbvn
CURL_DIR=$SPACK/curl-8.15.0-cjazhjsrdxhk7iz4ab3uhi4l7bjz2v4m
LIBPNG_DIR=$SPACK/libpng-1.6.47-ycrxqoudmaryqgkmx6hwjkfkvre752hh
NGHTTP2_DIR=$SPACK/nghttp2-1.67.1-piwrssdutlzmpf3z4m4qlunuucipemjx
FREETYPE_DIR=$SPACK/freetype-2.14.1-6pybd3weqnptd6at6uik2b2l44nrg6m7
LIBXML2_DIR=$SPACK/libxml2-2.13.5-qwekezfj7neddz4bmwmp2gcvsjwhh2qx
ZLIB_DIR=$SPACK/zlib-ng-2.2.4-xsdqw5trkbqasqg3a7icfcgbvmkplqph
BZIP2_DIR=$SPACK/bzip2-1.0.8-nfdr23txh3g62vraf3xriq4rhyp52onw
XZ_DIR=$SPACK/xz-5.6.3-2hto4bdxeyzcly6ezev4skpajs4j3qp7
LIBICONV_DIR=$SPACK/libiconv-1.18-6mxjfoxolhtgcrueot7mnz4355fwhyhh
FONTCONFIG_DIR=/ref/rmlab/software/tyron/fontconfig-devel
CAIRO_DIR=/ref/rmlab/software/tyron/cairo-devel
HARFBUZZ_DIR=/ref/rmlab/software/tyron/harfbuzz-devel
FRIBIDI_DIR=/ref/rmlab/software/tyron/fribidi-devel
LIBX11_DIR=/ref/rmlab/software/tyron/libX11-devel
XORGPROTO_DIR=/ref/rmlab/software/tyron/xorgproto-devel
LIBTIFF_DIR=/ref/rmlab/software/tyron/libtiff-devel
LIBJPEG_DIR=/ref/rmlab/software/tyron/libjpeg-devel
LIBWEBP_DIR=/ref/rmlab/software/tyron/libwebp-devel
IMAGEMAGICK_DIR=/ref/rmlab/software/tyron/imagemagick-devel
RAQM_LQR_DIR=/ref/rmlab/software/tyron/raqm-lqr-libs
HDF5_DIR=/ref/rmlab/software/tyron/hdf5-devel
FFTW_DIR=/ref/rmlab/software/tyron/fftw-devel
SPATIAL_DIR=/ref/rmlab/software/tyron/spatial-devel
UDUNITS2_DIR=/ref/rmlab/software/tyron/udunits2-devel
ODBC_DIR=/ref/rmlab/software/tyron/odbc-libs
OPENSSL_DIR=$SPACK/openssl-3.6.0-hdu4phhqvbzn54grs4bbnfjpbma7zlux
export PATH=$CMAKE_DIR/bin:$CURL_DIR/bin:$LIBPNG_DIR/bin:$LIBXML2_DIR/bin:$PATH
export PKG_CONFIG_PATH=$CAIRO_DIR/pkgconfig:$FONTCONFIG_DIR/pkgconfig:$HARFBUZZ_DIR/pkgconfig:$FRIBIDI_DIR/pkgconfig:$LIBX11_DIR/pkgconfig:$LIBTIFF_DIR/pkgconfig:$LIBJPEG_DIR/pkgconfig:$LIBWEBP_DIR/pkgconfig:$IMAGEMAGICK_DIR/pkgconfig:$HDF5_DIR/pkgconfig:$FFTW_DIR/usr/lib64/pkgconfig:$SPATIAL_DIR/usr/lib64/pkgconfig:$UDUNITS2_DIR/usr/lib64/pkgconfig:$CURL_DIR/lib/pkgconfig:$LIBPNG_DIR/lib64/pkgconfig:$NGHTTP2_DIR/lib/pkgconfig:$FREETYPE_DIR/lib/pkgconfig:$LIBXML2_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig:$BZIP2_DIR/lib/pkgconfig:${PKG_CONFIG_PATH:-}
export PATH=$SPATIAL_DIR/usr/bin:$HDF5_DIR/usr/bin:$CMAKE_DIR/bin:$CURL_DIR/bin:$LIBPNG_DIR/bin:$LIBXML2_DIR/bin:$PATH
export CPATH=$CAIRO_DIR/usr/include:$FONTCONFIG_DIR/usr/include:$HARFBUZZ_DIR/usr/include:$FRIBIDI_DIR/usr/include:$LIBX11_DIR/usr/include:$XORGPROTO_DIR/usr/include:$LIBTIFF_DIR/usr/include:$LIBJPEG_DIR/usr/include:$LIBWEBP_DIR/usr/include:$IMAGEMAGICK_DIR/usr/include:$HDF5_DIR/usr/include:$FFTW_DIR/usr/include:$SPATIAL_DIR/usr/include:$UDUNITS2_DIR/usr/include:$CURL_DIR/include:$LIBPNG_DIR/include:$NGHTTP2_DIR/include:$FREETYPE_DIR/include:$LIBXML2_DIR/include:$BZIP2_DIR/include:${CPATH:-}
export LIBRARY_PATH=$FONTCONFIG_DIR/usr/lib64:$CAIRO_DIR/usr/lib64:$HARFBUZZ_DIR/usr/lib64:$FRIBIDI_DIR/usr/lib64:$LIBX11_DIR/usr/lib64:$LIBTIFF_DIR/usr/lib64:$LIBJPEG_DIR/usr/lib64:$LIBWEBP_DIR/usr/lib64:$IMAGEMAGICK_DIR/usr/lib64:$FFTW_DIR/usr/lib64:$SPATIAL_DIR/usr/lib64:$UDUNITS2_DIR/usr/lib64:$ODBC_DIR/usr/lib64:$CURL_DIR/lib:$LIBPNG_DIR/lib64:$NGHTTP2_DIR/lib:$FREETYPE_DIR/lib:$LIBXML2_DIR/lib:$ZLIB_DIR/lib:$BZIP2_DIR/lib:${LIBRARY_PATH:-}
export LD_LIBRARY_PATH=$CURL_DIR/lib:$OPENSSL_DIR/lib64:$LIBPNG_DIR/lib64:$NGHTTP2_DIR/lib:$FREETYPE_DIR/lib:$LIBXML2_DIR/lib:$ZLIB_DIR/lib:${XZ_DIR}/lib:${LIBICONV_DIR}/lib:$IMAGEMAGICK_DIR/usr/lib64:$RAQM_LQR_DIR/usr/lib64:$FFTW_DIR/usr/lib64:$SPATIAL_DIR/usr/lib64:$UDUNITS2_DIR/usr/lib64:$ODBC_DIR/usr/lib64:/usr/lib64:${LD_LIBRARY_PATH:-}
export LDFLAGS="-L${HDF5_DIR}/usr/lib64 -L${UDUNITS2_DIR}/usr/lib64 -L${LIBXML2_DIR}/lib -L${ZLIB_DIR}/lib -L${BZIP2_DIR}/lib -L${FONTCONFIG_DIR}/usr/lib64 -L${CAIRO_DIR}/usr/lib64 -L${HARFBUZZ_DIR}/usr/lib64 -L${FRIBIDI_DIR}/usr/lib64 -L${LIBX11_DIR}/usr/lib64 -L${LIBTIFF_DIR}/usr/lib64 -L${LIBJPEG_DIR}/usr/lib64 -L${LIBWEBP_DIR}/usr/lib64 -L${FFTW_DIR}/usr/lib64 -L${SPATIAL_DIR}/usr/lib64 -L${ODBC_DIR}/usr/lib64 -Wl,-rpath-link,${SPATIAL_DIR}/usr/lib64 -Wl,-rpath-link,${ODBC_DIR}/usr/lib64 ${LDFLAGS:-}"
export UDUNITS2_XML_PATH=$UDUNITS2_DIR/usr/share/udunits/udunits2.xml
export UDUNITS2_INCLUDE=$UDUNITS2_DIR/usr/include
export UDUNITS2_LIBS="-L${UDUNITS2_DIR}/usr/lib64 -ludunits2"
export GDAL_CONFIG=$SPATIAL_DIR/usr/bin/gdal-config
export GEOS_CONFIG=$SPATIAL_DIR/usr/bin/geos-config
export PROJ_DATA=$SPATIAL_DIR/usr/share/proj
export PROJ_LIB=$SPATIAL_DIR/usr/share/proj
export MAGICK_CONFIGURE_PATH=$IMAGEMAGICK_DIR/etc/ImageMagick-6
export MAGICK_CODER_MODULE_PATH=$IMAGEMAGICK_DIR/usr/lib64/ImageMagick-6.9.13/modules-Q16/coders

mkdir -p "$R_LIBS"

# Remove any stale locks from previous failed installs
find "$R_LIBS" -maxdepth 1 -name "00LOCK-*" -type d -exec rm -rf {} + 2>/dev/null || true

echo "=== GitHub Package Install ==="
echo "R: $(${R_BIN}/R --version | head -1)"
echo "Library: $R_LIBS"
echo "Start: $(date)"

${R_BIN}/Rscript - <<'REOF'
lib <- Sys.getenv("R_LIBS")
.libPaths(c(lib, .libPaths()))

if (!requireNamespace("remotes", lib.loc = lib, quietly = TRUE)) {
  stop("remotes not found — run 01_cran.sh first")
}

# repo slug -> expected package name after install
repos <- list(
  "chris-mcginnis-ucsf/DoubletFinder"  = "DoubletFinder",
  "bnprks/BPCells/r"                   = "BPCells",
  "mojaveazure/seurat-disk"            = "SeuratDisk",
  "immunogenomics/harmony"             = "harmony",
  "immunogenomics/presto"              = "presto",
  "cole-trapnell-lab/monocle3"         = "monocle3",
  "satijalab/seurat-wrappers"          = "SeuratWrappers",
  "satijalab/seurat-data"              = "SeuratData",
  "igrabski/sc-SHC"                    = "scSHC",
  "crazyhottommy/scclusteval"          = "scclusteval",
  "guokai8/scGSVA"                     = "scGSVA",
  "cole-trapnell-lab/garnett"          = "garnett",
  "the-ouyang-lab/ShinyCell2"          = "ShinyCell2",
  "GfellerLab/EPIC"                    = "EPIC",
  "xuranw/MuSiC"                       = "MuSiC",
  "renozao/xbioc"                      = "xbioc",
  "Jiaxin-Fan/MuSiC2"                  = "MuSiC2",
  "campbio/decontX"                    = "decontX"
)

failed <- character(0)

install_one <- function(repo, pkg_name, lib) {
  for (attempt in 1:3) {
    ok <- tryCatch({
      remotes::install_github(repo, lib = lib, upgrade = "never",
                              dependencies = c("Depends", "Imports", "LinkingTo"))
      requireNamespace(pkg_name, lib.loc = lib, quietly = TRUE)
    }, error = function(e) {
      cat(sprintf("  attempt %d error: %s\n", attempt, conditionMessage(e)))
      FALSE
    })
    if (isTRUE(ok)) return(TRUE)
    if (attempt < 3) Sys.sleep(15)
  }
  FALSE
}

for (repo in names(repos)) {
  pkg_name <- repos[[repo]]
  if (requireNamespace(pkg_name, lib.loc = lib, quietly = TRUE)) {
    cat(sprintf("SKIP (already installed): %s\n", pkg_name))
    next
  }
  cat(sprintf("\n=== Installing: %s (%s) ===\n", pkg_name, repo))
  if (install_one(repo, pkg_name, lib)) {
    cat(sprintf("OK: %s\n", pkg_name))
  } else {
    cat(sprintf("FAILED: %s\n", repo))
    failed <- c(failed, repo)
  }
}

if (length(failed) > 0) {
  cat("\n--- FAILED REPOS ---\n")
  cat(paste(failed, collapse = "\n"), "\n")
  writeLines(failed, file.path(lib, "failed_03_github.txt"))
  cat("\nTo retry a single package:\n")
  cat("  remotes::install_github('<repo>', lib='", lib, "', dependencies=TRUE)\n", sep = "")
} else {
  cat("\n=== All GitHub packages installed successfully ===\n")
  f <- file.path(lib, "failed_03_github.txt")
  if (file.exists(f)) file.remove(f)
}
REOF

echo "End: $(date)"
