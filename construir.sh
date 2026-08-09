#!/bin/sh

BUILD_DIR="build"
REPO_DIR="repo"
NOMBRE_DEB="NubeSky.deb"

echo " 1. Ajustando permisos de seguridad..."
chmod 755 "$BUILD_DIR/DEBIAN"
chmod 644 "$BUILD_DIR/DEBIAN/control"
chmod 755 "$BUILD_DIR/usr/bin/"* 2>/dev/null

echo " 2. Compilando nuevo paquete..."
dpkg-deb --build "$BUILD_DIR" "$NOMBRE_DEB"

if [ $? -ne 0 ]; then
  echo "Error"
fi

echo " 3. Moviendo a la carpeta $REPO_DIR..."
mkdir -p "$REPO_DIR"
mv "$NOMBRE_DEB" "$REPO_DIR/$NOMBRE_DEB"

cd "$REPO_DIR" || exit
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cd -

echo "Listo lol"
echo "Ahora ejecuta: "
echo " git add . despues git commit -m 'lol' y finalmente git push"

