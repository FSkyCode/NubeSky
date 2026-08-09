#!/bin/sh

BUILD_DIR="build"
REPO_DIR="repo"
NOMBRE_DEB="NubeSky.deb"

echo " 1. Ajustando permisos de seguridad..."
chmod 755 "$BUILD_DIR/DEBIAN"
chmod 644 "$BUILD_DIR/DEBIAN/control"
# Otorga permisos 755 a todo lo que esté en usr/ (bin y share)
chmod -R 755 "$BUILD_DIR/usr"

echo " 2. Compilando nuevo paquete..."
dpkg-deb --build "$BUILD_DIR" "$NOMBRE_DEB"

# Si dpkg-deb falla, se detiene el script de inmediato
if [ $? -ne 0 ]; then
  echo "❌ Error en la compilación del paquete."
  exit 1
fi

echo " 3. Moviendo a la carpeta $REPO_DIR..."
mkdir -p "$REPO_DIR"
mv "$NOMBRE_DEB" "$REPO_DIR/$NOMBRE_DEB"

# Entramos a repo, generamos el índice y regresamos
cd "$REPO_DIR" || exit 1
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cd ..

echo "🚀 Listo lol"
echo "Ahora ejecuta:"
echo " git add . && git commit -m 'Update package' && git push"

