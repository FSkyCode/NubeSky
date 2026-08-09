const express = require('express');
const { MongoClient } = require('mongodb');
const app = express();
const PORT = 3000;

// 🔗 REEMPLAZA ESTO CON TU CADENA DE CONEXIÓN REAL DE MONGODB ATLAS
const uri = "mongodb+srv://FSkyCode:AdanEvaEden20*@clustersky.5knt0nd.mongodb.net/?appName=ClusterSky"

const client = new MongoClient(uri);
let db, notasCollection;

// Conectar a MongoDB antes de iniciar el servidor web
async function connectDB() {
    try {
        await client.connect();
        db = client.db('SystemSkyDB'); // Nombre de la base de datos
        notasCollection = db.collection('notas'); // Nombre de la colección
        console.log("🌠 [SystemSky] ¡Conectado exitosamente a MongoDB Atlas en la nube!");
    } catch (err) {
        console.error("❌ Error conectando a MongoDB:", err);
        process.exit(1);
    }
}
connectDB();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTML del inicio: Lee las notas desde la nube
app.get('/', async (req, res) => {
    try {
        const notas = await notasCollection.find({}).toArray();
        
        // 1. Agrupar las notas por carpeta en un objeto de JavaScript
        const carpetas = {};
        notas.forEach(n => {
            // Si la nota no tiene carpeta, la mandamos a "Sin Carpeta"
            const nombreCarpeta = n.carpeta || "Sin Carpeta";
            if (!carpetas[nombreCarpeta]) {
                carpetas[nombreCarpeta] = [];
            }
            carpetas[nombreCarpeta].push(n);
        });

        // 2. Generar el HTML organizado por secciones
        let listHtml = "";
        for (const [nombreCarpeta, notasDeCarpeta] of Object.entries(carpetas)) {
            listHtml += `
                <div style="margin-top: 20px; border-left: 3px solid #4CAF50; padding-left: 10px;">
                    <h4 style="margin: 0; color: #4CAF50; text-transform: uppercase;">📁 ${nombreCarpeta}</h4>
                    <ul style="list-style: none; padding-left: 15px; margin-top: 5px;">
            `;
            
            notasDeCarpeta.forEach(n => {
                listHtml += `
                    <li style="margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; max-width: 400px;">
                        <a href="/nota/${encodeURIComponent(n.titulo)}">${n.titulo}</a>
                        <form action="/eliminar" method="POST" style="display:inline; margin:0;">
                            <input type="hidden" name="titulo" value="${n.titulo}">
                            <button type="submit" style="padding: 2px 6px; font-size: 11px; background-color: #ff4d4d; color: white; border: none; border-radius: 4px; cursor: pointer;">X</button>
                        </form>
                    </li>
                `;
            });
            
            listHtml += `</ul></div>`;
        }

        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>SystemSky - for FSkyCode</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
                    textarea { width: 100%; height: 150px; font-size: 16px; margin-top: 10px; }
                    input[type="text"] { width: 100%; padding: 8px; font-size: 16px; box-sizing: border-box; margin-bottom: 10px; }
                    button { padding: 10px 20px; font-size: 16px; margin-top: 10px; cursor: pointer; }
                </style>
            </head>
            <body>
                <h1>🌠 NubeSky</h1>
                <h3>Crear o Editar Nota</h3>
                <form action="/guardar" method="POST">
                    <input type="text" name="carpeta" placeholder="Carpeta (Ej: Quimica, Proyecto1/s, Personal)">
                    <input type="text" name="titulo" placeholder="Título de la nota" required>
                    <textarea name="contenido" placeholder="Escribe tu nota aquí..." required></textarea>
                    <br>
                    <button type="submit" style="background-color: #4CAF50; color: white; border: none; border-radius: 4px;">Guardar en la Nube</button>
                </form>

                <h3>Mis Carpetas Sincronizadas</h3>
                ${listHtml || '<p>No hay notas en la nube aún.</p>'}
            </body>
            </html>
        `);
    } catch (err) {
        res.status(500).send("Error leyendo la base de datos.");
    }
});



// Ruta para ver/editar una nota específica
app.get('/nota/:titulo', async (req, res) => {
    try {
        const nota = await notasCollection.findOne({ titulo: req.params.titulo });
        if (nota) {
            res.send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Editar: ${nota.titulo}</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { font-family: sans-serif; max-width: 600px; margin: 20px auto; padding: 10px; }
                        textarea { width: 100%; height: 200px; font-size: 16px; margin-bottom: 10px; }
                        input[type="text"] { width: 100%; padding: 8px; margin-bottom: 10px; font-size: 16px; }
                        button { padding: 10px 20px; font-size: 16px; background: #28a745; color: white; border: none; border-radius: 5px; cursor: pointer; }
                    </style>
                </head>
                <body>
                    <h1>📝 Editando: ${nota.titulo}</h1>
                    <form action="/guardar" method="POST">
                        <input type="text" name="titulo" value="${nota.titulo}" readonly>
                        <textarea name="contenido" required>${nota.contenido}</textarea>
                        <br>
                        <button type="submit">Actualizar en la Nube</button>
                    </form>
                    <br>
                    <a href="/">⬅️ Volver al inicio</a>
                </body>
                </html>
            `);
        } else {
            res.redirect('/');
        }
    } catch (err) {
        res.status(500).send("Error al buscar la nota.");
    }
});

// Guardar o actualizar nota en MongoDB (Upsert)
app.post('/guardar', async (req, res) => {
    try {
        const { carpeta, titulo, contenido } = req.body;

        // Limpiamos el nombre de la carpeta por si ponen espacios en blanco
        const nombreCarpeta = carpeta.trim() || "Sin Carpeta";

        // Guardamos o actualizamos en MongoDB incluyendo la propiedad carpeta
        await notasCollection.updateOne(
            { titulo: titulo },
            { $set: { carpeta: nombreCarpeta, contenido: contenido } },
            { upsert: true } // Esto hace que si no existe la cree, y si existe la actualice
        );

        console.log(`💾 Nota guardada en carpeta [${nombreCarpeta}]: ${titulo}`);
        res.redirect('/');
    } catch (err) {
        console.error("Error al guardar:", err);
        res.status(500).send("Error al guardar en la base de datos.");
    }
});


// Ruta para eliminar una nota usando su título
app.post('/eliminar', async (req, res) => {
    try {
        const tituloNota = req.body.titulo;

        // Comando de MongoDB para borrar un solo documento que coincida con el título
        await notasCollection.deleteOne({ titulo: tituloNota });

        console.log(`🗑️ Nota eliminada: ${tituloNota}`);
        
        // Redireccionar al inicio para refrescar la lista de notas automáticamente
        res.redirect('/');
    } catch (err) {
        console.error("Error al eliminar la nota:", err);
        res.status(500).send("Error al intentar eliminar la nota de la base de datos.");
    }
});



app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor SystemSky activo en http://localhost:${PORT}`);
});
