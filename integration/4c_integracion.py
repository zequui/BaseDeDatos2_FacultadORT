import oracledb
import pymongo
import datetime
import random

# ------------------------------------------------------------
# CONFIGURACIÓN DE CONEXIONES
# ------------------------------------------------------------
ORACLE_DSN  = "localhost:1521/XE"   
ORACLE_USER = "BD_1" 
ORACLE_PASS = "alumno" 

MONGO_URI = "mongodb://localhost:27017"
MONGO_DB = "moltbook"
MONGO_COLL = "eventos"

# ------------------------------------------------------------
# CONEXIÓN A ORACLE
# ------------------------------------------------------------
oracle_conn = oracledb.connect(user=ORACLE_USER, password=ORACLE_PASS, dsn=ORACLE_DSN)
cursor = oracle_conn.cursor()

# ------------------------------------------------------------
# CONEXIÓN A MONGODB
# ------------------------------------------------------------
mongo_client = pymongo.MongoClient(MONGO_URI)
db = mongo_client[MONGO_DB]
eventos = db[MONGO_COLL]

# Eliminar colección si existe (para pruebas) y crear con validador flexible para Python
eventos.drop()
db.create_collection(
    "eventos",
    validator={
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["agente_id", "nombre_agente", "tipo_evento", "criticidad", "fecha", "detalle"],
            "properties": {
                # CORRECCIÓN: Permitir int y long para evitar fallos de tipos en Python
                "agente_id": {"bsonType": ["int", "long"]},
                "nombre_agente": {"bsonType": "string"},
                "tipo_evento": {
                    "enum": [
                        "decision",
                        "interaccion_usuario",
                        "accion",
                        "metrica_ejecucion",
                        "anomalia",
                        "creacion_publicacion",
                        "creacion_comentario",
                        "voto"
                    ]
                },
                "criticidad": {"enum": ["alta", "media", "baja"]},
                "fecha": {"bsonType": "date"},
                "id_comunidad": {"bsonType": ["int", "long", "null"]},
                "detalle": {
                    "bsonType": "object",
                    "additionalProperties": True  
                }
            }
        }
    }
)

# ------------------------------------------------------------
# FUNCIONES AUXILIARES PARA GENERAR EVENTOS
# ------------------------------------------------------------
def get_agente_info(agente_id):
    cursor.execute("""
        SELECT a.id, a.nombre, a.tipo, u.mail, u.activo
        FROM AGENTE a JOIN USUARIO u ON a.id_usuario = u.mail
        WHERE a.id = :id
    """, id=agente_id)
    row = cursor.fetchone()
    if row:
        return {
            "id": row[0],
            "nombre": row[1],
            "tipo": row[2],
            "usuario_mail": row[3],
            "usuario_activo": row[4]
        }
    return None

def generar_evento_publicacion(agente_id, nombre_agente, contenido_id, titulo, comunidad_id, fecha):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "creacion_publicacion",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "id_publicacion": int(contenido_id),
            "titulo": titulo
        }
    }

def generar_evento_comentario(agente_id, nombre_agente, contenido_id, comunidad_id, fecha, id_publicacion=None, id_comentario_padre=None):
    detalle = {"id_comentario": int(contenido_id)}
    if id_publicacion is not None:
        detalle["id_publicacion"] = int(id_publicacion)
    if id_comentario_padre is not None:
        detalle["id_comentario_padre"] = int(id_comentario_padre)
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "creacion_comentario",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": detalle
    }

def generar_evento_voto(agente_id, nombre_agente, pub_id, fecha, positivo):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "voto",
        "criticidad": "baja",
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "id_publicacion": int(pub_id),
            "positivo": bool(positivo)
        }
    }

def generar_evento_accion(agente_id, nombre_agente, tipo_accion, contenido_id, comunidad_id, fecha, criticidad="media"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "accion",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "tipo_accion": tipo_accion,
            "id_contenido": int(contenido_id)
        }
    }

def generar_evento_decision(agente_id, nombre_agente, comunidad_id, fecha, contexto, params, alternativas, elegida, criticidad="baja"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "decision",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": int(comunidad_id) if comunidad_id else None,
        "detalle": {
            "contexto_operacional": contexto,
            "parametros_entrada": params,
            "alternativas_evaluadas": alternativas,
            "alternativa_elegida": elegida
        }
    }

def generar_evento_metrica(agente_id, nombre_agente, fecha, tiempo_ms, tokens, criticidad="baja"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "metrica_ejecucion",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "tiempo_respuesta_ms": tiempo_ms,
            "tokens_procesados": tokens
        }
    }

def generar_evento_anomalia(agente_id, nombre_agente, fecha, patron, descripcion, criticidad="alta"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "anomalia",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "patron_detectado": patron,
            "descripcion": descripcion
        }
    }

def generar_evento_interaccion(agente_id, nombre_agente, fecha, usuario_mail, canal, criticidad="media"):
    return {
        "agente_id": int(agente_id),
        "nombre_agente": nombre_agente,
        "tipo_evento": "interaccion_usuario",
        "criticidad": criticidad,
        "fecha": fecha,
        "id_comunidad": None,
        "detalle": {
            "id_usuario": usuario_mail,
            "canal": canal
        }
    }

# ------------------------------------------------------------
# 1. MIGRACIÓN SINCED DESDE ORACLE
# ------------------------------------------------------------
print("Migrando datos reales desde Oracle...")

# Publicaciones
cursor.execute("SELECT c.id, c.id_agente, c.id_comunidad, p.titulo, c.fechaCreacion, c.horaCreacion FROM CONTENIDO c JOIN PUBLICACION p ON c.id = p.id")
for row in cursor:
    contenido_id, agente_id, comunidad_id, titulo, f_c, h_c = row
    fecha = datetime.datetime.combine(f_c, datetime.datetime.strptime(h_c, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        eventos.insert_one(generar_evento_publicacion(agente_id, info["nombre"], contenido_id, titulo, comunidad_id, fecha))

# Comentarios
cursor.execute("""
    SELECT c.id, c.id_agente, c.id_comunidad, co.contenido,
           c.fechaCreacion, c.horaCreacion,
           co.id_publicacion, co.id_comentario_padre
    FROM CONTENIDO c JOIN COMENTARIO co ON c.id = co.id
""")
for row in cursor:
    contenido_id, agente_id, comunidad_id, contenido, f_c, h_c, id_pub, id_com_padre = row
    fecha = datetime.datetime.combine(f_c, datetime.datetime.strptime(h_c, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        eventos.insert_one(generar_evento_comentario(agente_id, info["nombre"], contenido_id, comunidad_id, fecha, id_pub, id_com_padre))
# Votos
cursor.execute("SELECT id_agente, id_publicacion, fecha, hora, positivo FROM VOTA")
for row in cursor:
    agente_id, pub_id, f_v, h_v, positivo = row
    fecha = datetime.datetime.combine(f_v, datetime.datetime.strptime(h_v, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        eventos.insert_one(generar_evento_voto(agente_id, info["nombre"], pub_id, fecha, positivo))

# Moderaciones
cursor.execute("SELECT id_agente, id_contenido, id_comunidad, tipo, fecha, hora FROM INTERVIENE")
for row in cursor:
    agente_id, contenido_id, comunidad_id, tipo_mod, f_m, h_m = row
    fecha = datetime.datetime.combine(f_m, datetime.datetime.strptime(h_m, "%H:%M:%S").time())
    info = get_agente_info(agente_id)
    if info:
        eventos.insert_one(generar_evento_accion(agente_id, info["nombre"], "moderacion", contenido_id, comunidad_id, fecha, criticidad="alta"))


# ------------------------------------------------------------
# 2. INYECCIÓN EXTRA ESTRATÉGICA PARA REQUERIMIENTOS 5.1, 5.2 Y 5.3
# ------------------------------------------------------------
print("Inyectando casos de prueba dedicados para las consultas obligatorias...")

# --- Para Req 5.1: Decisiones específicas año 2026 para Agente 5 ---
info_a5 = get_agente_info(5)
if info_a5:
    eventos.insert_one(generar_evento_decision(
        5, info_a5["nombre"], 2, datetime.datetime(2026, 6, 22, 10, 30, 0),
        "seleccion_contenido_publicacion", {"categoria": "Data Science"},
        ["Pandas 3.0", "Numpy Avanzado"], "Pandas 3.0", "media"
    ))
    eventos.insert_one(generar_evento_decision(
        5, info_a5["nombre"], 2, datetime.datetime(2026, 6, 22, 11, 45, 0),
        "generacion_respuesta", {"max_tokens": 150},
        ["Aprobar comentario", "Descartar"], "Aprobar comentario", "baja"
    ))

# --- Para Req 5.2: Top 5 Agentes con más criticidad ALTA en la última semana ---
# Aseguramos volumen en la fecha actual (Junio 2026)
ahora = datetime.datetime.now()
for i in [1, 2, 3, 4, 6]:
    info_ag = get_agente_info(i)
    if info_ag:
        # Insertar 3 eventos de criticidad ALTA para cada uno para que peleen el TOP 5
        for _ in range(3):
            eventos.insert_one(generar_evento_anomalia(i, info_ag["nombre"], ahora - datetime.timedelta(days=1), "comportamiento_anomalo", "Exceso de peticiones concurrentes", "alta"))
        # Insertar 2 eventos de criticidad BAJA para tener denominador en las proporciones
        for _ in range(2):
            eventos.insert_one(generar_evento_metrica(i, info_ag["nombre"], ahora - datetime.timedelta(days=2), 150, 45, "baja"))

# --- Para Req 5.3: Interacciones del Agente 1 distribuidas por Hora ---
info_a1 = get_agente_info(1)
if info_a1:
    # 2 interacciones en la hora 08
    eventos.insert_one(generar_evento_interaccion(1, info_a1["nombre"], datetime.datetime(2026, 6, 22, 8, 15, 0), "admin1@moltbook.com", "panel_admin", "baja"))
    eventos.insert_one(generar_evento_interaccion(1, info_a1["nombre"], datetime.datetime(2026, 6, 22, 8, 45, 0), "admin1@moltbook.com", "consulta_estado", "baja"))
    # 1 interacción en la hora 14
    eventos.insert_one(generar_evento_interaccion(1, info_a1["nombre"], datetime.datetime(2026, 6, 22, 14, 20, 0), "admin1@moltbook.com", "panel_admin", "baja"))


# ------------------------------------------------------------
# CIERRE DE CONEXIONES
# ------------------------------------------------------------
cursor.close()
oracle_conn.close()
mongo_client.close()

print("¡Integración y población completada con éxito!")