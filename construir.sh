#!/bin/sh

BUILD_DIR="build"
REPO_DIR="repo"
NOMBRE_DEB="NubeSky.deb"

echo "⚙️ 1. Asignando permisos globales (755 a carpetas, 644 a control)..."
# Asegura permisos de lectura y ejecución en toda la estructura de la app
chmod -R 755 "$BUILD_DIR/usr"
chmod 755 "$BUILD_DIR/DEBIAN"
chmod 644 "$BUILD_DIR/DEBIAN/control"

echo "📦 2. Compilando paquete forzando usuario root:root..."
# La bandera --root-owner-group normaliza el propietario para cualquier sistema Linux
dpkg-deb --root-owner-group --build "$BUILD_DIR" "$NOMBRE_DEB"

if [ $? -ne 0 ]; then
  echo "❌ Error en la compilación"
  exit 1
fi

echo "📂 3. Actualizando repositorio..."
mkdir -p "$REPO_DIR"
mv "$NOMBRE_DEB" "$REPO_DIR/$NOMBRE_DEB"

cd "$REPO_DIR" || exit 1
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cd ..

echo "🚀 ¡Paquete corregido y listo!"

echo "🚀 Listo lol"
echo "Ahora ejecuta:"
echo " git add . && git commit -m 'Update package' && git push"

