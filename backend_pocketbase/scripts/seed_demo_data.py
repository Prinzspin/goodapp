import random
import requests
import os
import time
from pocketbase import PocketBase
from pocketbase.client import FileUpload

# CONFIGURATION
PB_URL = "http://127.0.0.1:8090"
ADMIN_EMAIL = "admin@example.com"  # À MODIFIER si nécessaire
ADMIN_PASS = "admin123456"       # À MODIFIER si nécessaire

# IMAGES LIBRES (Wikimedia Commons)
IMAGE_SAMPLES = {
    "food": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Good_Food_Display_-_NCI_Visuals_Online.jpg/800px-Good_Food_Display_-_NCI_Visuals_Online.jpg",
    "music": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Musical_instruments_on_display_at_the_Musical_Instrument_Museum_in_Phoenix_AZ.jpg/800px-Musical_instruments_on_display_at_the_Musical_Instrument_Museum_in_Phoenix_AZ.jpg",
    "sport": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Football_in_Berlin.jpg/800px-Football_in_Berlin.jpg",
    "soiree": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Nightclub_party.jpg/800px-Nightclub_party.jpg",
    "expo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Louvre_Museum_Wikimedia_Commons.jpg/800px-Louvre_Museum_Wikimedia_Commons.jpg",
    "networking": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Business_Meeting_Networking.jpg/800px-Business_Meeting_Networking.jpg"
}

pb = PocketBase(PB_URL)

def download_image(url):
    temp_path = "temp_image.jpg"
    try:
        response = requests.get(url, stream=True, timeout=10)
        if response.status_code == 200:
            with open(temp_path, 'wb') as f:
                for chunk in response:
                    f.write(chunk)
            return temp_path
    except Exception as e:
        print(f"Erreur téléchargement image : {e}")
    return None

def seed():
    try:
        # 1. AUTHENTICATION SUPERUSER
        pb.admins.auth_with_password(ADMIN_EMAIL, ADMIN_PASS)
        print("✅ Authentifié en tant que Superuser")

        # 2. CREATE USERS
        user_ids = []
        names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Heidi", "Ivan", "Judy"]
        for name in names:
            email = f"{name.lower()}@demo.com"
            try:
                # Vérifie si l'utilisateur existe déjà
                existing = pb.collection("users").get_list(1, 1, {"filter": f'email="{email}"'})
                if existing.items:
                    user_ids.append(existing.items[0].id)
                    continue

                user = pb.collection("users").create({
                    "username": name.lower() + str(random.randint(10, 99)),
                    "email": email,
                    "password": "password123",
                    "passwordConfirm": "password123",
                    "name": name,
                    "bio": f"Passionné de {random.choice(list(IMAGE_SAMPLES.keys()))} - Membre démo Good App."
                })
                user_ids.append(user.id)
                print(f"👤 Utilisateur créé : {name}")
            except Exception as e:
                print(f"⚠️ Erreur utilisateur {name}: {e}")

        # 3. CREATE EVENTS
        categories = list(IMAGE_SAMPLES.keys())
        locations = [
            ("Paris - Tour Eiffel", 48.8584, 2.2945),
            ("Paris - Le Marais", 48.8575, 2.3614),
            ("Paris - Canal St-Martin", 48.8741, 2.3631),
            ("Paris - Montmartre", 48.8867, 2.3431),
            ("Paris - Bastille", 48.8531, 2.3691)
        ]

        event_ids = []
        for i in range(25):
            cat = random.choice(categories)
            loc = random.choice(locations)
            creator = random.choice(user_ids)
            title = f"{cat.capitalize()} {random.choice(['Génial', 'VIP', 'Communautaire', 'Afterwork', 'Chill'])} #{i+1}"
            
            try:
                # Éviter les doublons par titre
                if pb.collection("events").get_list(1, 1, {"filter": f'title="{title}"'}).items:
                    continue

                # Téléchargement photo
                img_path = download_image(IMAGE_SAMPLES[cat])
                
                data = {
                    "title": title,
                    "description": f"Venez nombreux pour cet événement {cat} ! Un moment de partage inoubliable au coeur de {loc[0]}.",
                    "start_date": f"2026-05-{random.randint(10, 28)} {random.randint(10, 20)}:00:00",
                    "is_public": random.choice([True, True, False]), # Plus de publics que de privés
                    "creator": creator,
                    "location_name": loc[0],
                    "lat": loc[1] + (random.uniform(-0.01, 0.01)),
                    "long": loc[2] + (random.uniform(-0.01, 0.01)),
                }

                # Upload photo si téléchargée
                files = []
                if img_path:
                    files.append(("photos", open(img_path, "rb")))

                event = pb.collection("events").create(data, files=files)
                event_ids.append(event.id)
                print(f"🎉 Événement créé : {title}")
                
                if img_path: os.remove(img_path) # Nettoyage
            except Exception as e:
                print(f"⚠️ Erreur événement {title}: {e}")

        # 4. MEMBRE, LIKES & MESSAGES (Laisser le temps aux hooks de créer les conversations)
        print("⏳ Attente des hooks backend (conversations)...")
        time.sleep(2)

        for event_id in event_ids:
            try:
                # Likes aléatoires
                for _ in range(random.randint(2, 6)):
                    u_id = random.choice(user_ids)
                    try:
                        pb.collection("event_likes").create({"event": event_id, "user": u_id})
                    except: pass # Ignore si déja liké

                # Membres aléatoires
                for _ in range(random.randint(3, 8)):
                    u_id = random.choice(user_ids)
                    try:
                        pb.collection("event_members").create({
                            "event": event_id,
                            "user": u_id,
                            "status": random.choice(["accepted", "accepted", "pending"]),
                            "role": "member"
                        })
                    except: pass

                # Messages dans la conversation auto-créée
                convs = pb.collection("conversations").get_list(1, 1, {"filter": f'event="{event_id}"'})
                if convs.items:
                    conv_id = convs.items[0].id
                    # Seuls les membres "accepted" peuvent envoyer (sécurité hook)
                    accepted_members = pb.collection("event_members").get_list(1, 20, {"filter": f'event="{event_id}" && status="accepted"'})
                    for mem in accepted_members.items:
                        pb.collection("messages").create({
                            "conversation": conv_id,
                            "author": mem.user,
                            "content": random.choice([
                                "Hâte d'y être !", "C'est à quelle heure déjà ?", 
                                "Est-ce qu'on peut ramener des amis ?", "Trop cool ce projet !",
                                "Est-ce qu'il y aura à manger ?", "On se retrouve devant ?"
                            ])
                        })
                print(f"✅ Activité générée pour l'événement {event_id}")

            except Exception as e:
                print(f"⚠️ Erreur activité event {event_id}: {e}")

        print("\n🚀 SEED TERMINÉ AVEC SUCCÈS !")

    except Exception as e:
        print(f"❌ ERREUR GLOBALE : {e}")

if __name__ == "__main__":
    seed()
