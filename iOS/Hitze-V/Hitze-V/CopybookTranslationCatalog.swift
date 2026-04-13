import Foundation

struct CopybookTranslationCatalog {
    static func translation(for language: ResolvedLanguage, english: String) -> String? {
        translations[language]?[english]
    }

    private static let translations: [ResolvedLanguage: [String: String]] = [
        .fr: [
            "Push notifications": "Notifications push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Choisissez si les alertes de chaleur doivent être envoyées sous forme de notifications push et pour quels lieux de travail.",
            "Enable push notifications": "Activer les notifications push",
            "Worksites for push": "Lieux de travail pour les notifications push",
            "Add a worksite first to control push notifications individually.": "Ajoutez d'abord un lieu de travail pour gérer les notifications push individuellement.",
            "No address available": "Aucune adresse disponible",
            "Turning this off immediately removes all current push subscriptions.": "La désactivation supprime immédiatement tous les abonnements push actuels.",
            "2 (apparent temperature ≥ 30 °C)": "2 (température ressentie ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (température ressentie ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (température ressentie ≥ 40 °C)",
            "Active Topic Subscriptions": "Abonnements actifs aux sujets",
            "Add": "Ajouter",
            "Address search failed. Please try again.": "La recherche d'adresse a échoué. Veuillez réessayer.",
            "Adjust schedules and actively protect teams.": "Adaptez les horaires et protégez activement les équipes.",
            "All clear. Standard precautions are sufficient.": "Rien à signaler. Les mesures standard suffisent.",
            "All day": "Toute la journée",
            "Allow & Start": "Autoriser et démarrer",
            "Appearance": "Apparence",
            "Apply Heat-V protective measures immediately.": "Appliquez immédiatement les mesures de protection Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "À partir d'un indice UV de 5, l'exposition augmente nettement. Utilisez systématiquement des vêtements de protection, un couvre-chef, des lunettes de soleil et de la crème solaire.",
            "Auto": "Auto",
            "Call 144 now": "Appeler le 144 maintenant",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Appelez les secours (144) si l'état ne s'améliore pas rapidement ou s'il y a des signes de perte de connaissance",
            "Cancel": "Annuler",
            "Choose a result": "Choisir un résultat",
            "City, Street...": "Ville, rue...",
            "Close": "Fermer",
            "Cool the body, e.g. with damp cloths or ventilation": "Refroidir le corps avec des linges humides, des compresses froides ou de la ventilation",
            "Create New Workplace": "Créer un nouveau lieu de travail",
            "Critical": "Critique",
            "Current Risk": "Risque actuel",
            "Dark": "Sombre",
            "Data source: GeoSphere Austria": "Source de données : GeoSphere Austria",
            "Delete workplace": "Supprimer le lieu de travail",
            "Development": "Développement",
            "Elevated": "Élevé",
            "Emergency measures": "Mesures d'urgence",
            "Feels Like": "Temp. ressentie",
            "GeoSphere test URL": "URL de test GeoSphere",
            "Green": "Vert",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Maux de tête, vertiges, nausées
            Faiblesse, crampes, confusion
            Peau chaude et sèche ou très transpirante
            Troubles de la conscience
            """,
            "Heat Protection Measures": "Mesures de protection contre la chaleur",
            "Heat Safety at a Glance": "Sécurité chaleur en un coup d'œil",
            "Heat protection checklist for businesses": "Liste de contrôle de protection contre la chaleur pour les entreprises",
            "Heat warning level": "Niveau d'alerte chaleur",
            "Heat warning scale": "Échelle des alertes chaleur",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Les symptômes liés à la chaleur peuvent inclure",
            "High": "Haut",
            "If set, this URL is used instead of the GeoSphere server.": "Si elle est définie, cette URL est utilisée à la place du serveur GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "En l'absence de respiration normale, commencez immédiatement la réanimation et appelez à l'aide",
            "If unconscious, place the person in the recovery position": "En cas d'inconscience, mettre la personne en position latérale de sécurité",
            "Increase breaks and shade usage.": "Augmentez les pauses et le recours à l'ombre.",
            "Info": "Info",
            "Info & Legal": "Infos et mentions légales",
            "Label (optional)": "Libellé (optionnel)",
            "Language": "Langue",
            "Later / Skip": "Plus tard / Ignorer",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Faire boire lentement (eau, thé, solutions électrolytiques)",
            "Light": "Clair",
            "Live data could not be loaded right now. Please try again later.": "Les données en direct n'ont pas pu être chargées pour le moment. Veuillez réessayer plus tard.",
            "Loading live data": "Chargement des données en direct",
            "Loosen clothing": "Desserrer les vêtements",
            "Maximum values across all workplaces": "Valeurs maximales sur l'ensemble des lieux de travail",
            "Mock active": "Mock actif",
            "Mock mode enabled": "Mode mock activé",
            "Mock mode stays active until the app is restarted.": "Le mode mock reste actif jusqu'au prochain redémarrage de l'application.",
            "Monitor consciousness and breathing until emergency services arrive": "Surveillez la conscience et la respiration jusqu'à l'arrivée des secours et restez avec la personne",
            "Monitored Workplaces": "Lieux de travail surveillés",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Déplacez si possible l'exposition directe au soleil et les travaux pénibles à l'ombre et limitez le temps passé en plein soleil.",
            "No active topic subscriptions": "Aucun abonnement actif à des sujets",
            "No matching address found.": "Aucune adresse correspondante trouvée.",
            "No workplaces yet.": "Aucun lieu de travail pour l'instant.",
            "Open info": "Ouvrir les infos",
            "Optional": "Optionnel",
            "Organizational measures": "Mesures organisationnelles",
            "Peak UV": "Pic UV",
            "Personal protective measures": "Mesures de protection individuelle",
            "Please enter an address.": "Veuillez saisir une adresse.",
            "Possible emergency measures": "Mesures d'urgence possibles",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Fournir suffisamment d'eau potable
            Vêtements de travail légers avec protection UV et crème solaire (SPF 50 recommandé), lunettes de protection UV, serviettes rafraîchissantes
            Selon le poste : casque de sécurité avec protège-nuque
            """,
            "Quick Glance": "Aperçu rapide",
            "Red": "Rouge",
            "Refresh data": "Actualiser les données",
            "Response plan (STOP principle)": "Programme de mesures (principe STOP)",
            "Search Address": "Rechercher une adresse",
            "Search address or place": "Rechercher une adresse ou un lieu",
            "Searching address...": "Recherche d'adresse...",
            "Settings": "Paramètres",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Ombrager les zones de travail et de repos avec des parasols, pavillons, etc.
            Utiliser des mesures techniques de refroidissement comme des ventilateurs
            Réduire les travaux physiquement pénibles, p. ex. grâce à des aides de levage
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Déplacer les horaires de travail : programmer les travaux lourds aux heures plus fraîches du matin
            Prévoir des pauses appropriées pour se rafraîchir
            Effectuer les travaux lourds à l'ombre ou dans des zones fraîches
            """,
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Afin de vous avertir à temps des niveaux de chaleur dangereux sur vos lieux de travail, nous avons besoin de votre autorisation pour les notifications push. Veuillez les autoriser à l'étape suivante.",
            "Stable": "Stable",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "À partir du niveau d'alerte chaleur 2 (dès 30 °C), un programme de mesures et des mesures d'urgence doivent être mis en œuvre. Les mesures possibles comprennent notamment :",
            "Stay informed": "Rester informé",
            "Stop work and move the affected person to shade or a cool place": "Arrêtez le travail et déplacez la personne concernée à l'ombre ou dans une pièce fraîche",
            "System": "Système",
            "System language": "Langue du système",
            "Technical measures": "Mesures techniques",
            "The workplace could not be added.": "Le lieu de travail n'a pas pu être ajouté.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Cette session affiche désormais des niveaux d'alerte aléatoires pour tous les lieux de travail. Le mode sera désactivé au prochain redémarrage.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Cette zone se trouve probablement hors d'Autriche ou n'est pas reconnue par GeoSphere. Impossible de l'ajouter.",
            "Today": "Aujourd'hui",
            "Topics": "Sujets",
            "Traffic-light status, UV and workplaces live in one view.": "Statut du feu, UV et lieux de travail en direct en un coup d'œil.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Indice UV >= 5",
            "UV Protection Measures": "Mesures de protection UV",
            "Unable to add": "Ajout impossible",
            "Warnings": "Avertissements",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Nous vous aidons à respecter les exigences légales liées aux risques de chaleur et de rayonnement UV naturel lors du travail en extérieur. Gardez toujours un œil sur les températures et l'indice UV.",
            "Welcome to Hitze-V": "Bienvenue sur Hitze-V",
            "Workplaces": "Lieux de travail",
            "Yellow": "Jaune",
            "n/a": "n/d",
        ],
        .es: [
            "Push notifications": "Notificaciones push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Elige si las alertas de calor deben enviarse como notificaciones push y para qué lugares de trabajo.",
            "Enable push notifications": "Activar notificaciones push",
            "Worksites for push": "Lugares de trabajo para notificaciones push",
            "Add a worksite first to control push notifications individually.": "Primero añade un lugar de trabajo para controlar las notificaciones push individualmente.",
            "No address available": "No hay dirección disponible",
            "Turning this off immediately removes all current push subscriptions.": "Al desactivar esto se eliminan inmediatamente todas las suscripciones push actuales.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatura aparente ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatura aparente ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatura aparente ≥ 40 °C)",
            "Active Topic Subscriptions": "Suscripciones activas a temas",
            "Add": "Añadir",
            "Address search failed. Please try again.": "La búsqueda de direcciones ha fallado. Inténtalo de nuevo.",
            "Adjust schedules and actively protect teams.": "Ajusta los horarios y protege activamente a los equipos.",
            "All clear. Standard precautions are sufficient.": "Todo en orden. Las medidas estándar son suficientes.",
            "All day": "Todo el día",
            "Allow & Start": "Permitir y empezar",
            "Appearance": "Apariencia",
            "Apply Heat-V protective measures immediately.": "Aplica de inmediato las medidas de protección Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Con un índice UV de 5 o superior, la exposición aumenta de forma considerable. Usa siempre ropa de protección, cobertura para la cabeza, gafas de sol y protector solar.",
            "Auto": "Auto",
            "Call 144 now": "Llamar ahora al 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Llama a emergencias (144) si el estado no mejora pronto o hay signos de pérdida de consciencia",
            "Cancel": "Cancelar",
            "Choose a result": "Elige un resultado",
            "City, Street...": "Ciudad, calle...",
            "Close": "Cerrar",
            "Cool the body, e.g. with damp cloths or ventilation": "Enfría el cuerpo con paños húmedos, compresas frías o ventilación",
            "Create New Workplace": "Crear nuevo lugar de trabajo",
            "Critical": "Crítico",
            "Current Risk": "Riesgo actual",
            "Dark": "Oscuro",
            "Data source: GeoSphere Austria": "Fuente de datos: GeoSphere Austria",
            "Delete workplace": "Eliminar lugar de trabajo",
            "Development": "Desarrollo",
            "Elevated": "Elevado",
            "Emergency measures": "Medidas de emergencia",
            "Feels Like": "Sensación térmica",
            "GeoSphere test URL": "URL de prueba de GeoSphere",
            "Green": "Verde",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Dolor de cabeza, mareos, náuseas
            Debilidad, calambres, confusión
            Piel caliente y seca o piel muy sudorosa
            Alteración de la consciencia
            """,
            "Heat Protection Measures": "Medidas de protección frente al calor",
            "Heat Safety at a Glance": "Seguridad frente al calor de un vistazo",
            "Heat protection checklist for businesses": "Lista de comprobación de protección frente al calor para empresas",
            "Heat warning level": "Nivel de alerta por calor",
            "Heat warning scale": "Escala de alerta por calor",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Los síntomas relacionados con el calor pueden incluir",
            "High": "Alto",
            "If set, this URL is used instead of the GeoSphere server.": "Si se define, esta URL se utiliza en lugar del servidor de GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Si no hay respiración normal, inicia de inmediato la reanimación y pide ayuda",
            "If unconscious, place the person in the recovery position": "Si está inconsciente, coloca a la persona en posición lateral de seguridad",
            "Increase breaks and shade usage.": "Aumenta las pausas y el uso de la sombra.",
            "Info": "Información",
            "Info & Legal": "Información y legal",
            "Label (optional)": "Etiqueta (opcional)",
            "Language": "Idioma",
            "Later / Skip": "Más tarde / Omitir",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Haz que beba lentamente (agua, té, soluciones con electrolitos)",
            "Light": "Claro",
            "Live data could not be loaded right now. Please try again later.": "No se han podido cargar los datos en vivo en este momento. Inténtalo de nuevo más tarde.",
            "Loading live data": "Cargando datos en vivo",
            "Loosen clothing": "Aflojar la ropa",
            "Maximum values across all workplaces": "Valores máximos de todos los lugares de trabajo",
            "Mock active": "Mock activo",
            "Mock mode enabled": "Modo mock activado",
            "Mock mode stays active until the app is restarted.": "El modo mock permanece activo hasta el próximo reinicio de la aplicación.",
            "Monitor consciousness and breathing until emergency services arrive": "Controla la consciencia y la respiración hasta que lleguen los servicios de emergencia y permanece con la persona",
            "Monitored Workplaces": "Lugares de trabajo supervisados",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Traslada siempre que sea posible la exposición directa al sol y el trabajo exigente a la sombra, y limita el tiempo bajo el sol pleno.",
            "No active topic subscriptions": "No hay suscripciones activas a temas",
            "No matching address found.": "No se ha encontrado ninguna dirección coincidente.",
            "No workplaces yet.": "Todavía no hay lugares de trabajo.",
            "Open info": "Abrir información",
            "Optional": "Opcional",
            "Organizational measures": "Medidas organizativas",
            "Peak UV": "Pico UV",
            "Personal protective measures": "Medidas de protección personal",
            "Please enter an address.": "Introduce una dirección.",
            "Possible emergency measures": "Posibles medidas de emergencia",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Proporcionar suficiente agua potable
            Ropa de trabajo ligera con protección UV y protector solar (SPF 50 recomendado), gafas de protección UV, toallas refrescantes
            Según el puesto: casco de protección con protector de nuca
            """,
            "Quick Glance": "Vista rápida",
            "Red": "Rojo",
            "Refresh data": "Actualizar datos",
            "Response plan (STOP principle)": "Programa de medidas (principio STOP)",
            "Search Address": "Buscar dirección",
            "Search address or place": "Buscar dirección o lugar",
            "Searching address...": "Buscando dirección...",
            "Settings": "Ajustes",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Sombrar las zonas de trabajo y descanso con sombrillas, carpas, etc.
            Utilizar medidas técnicas de refrigeración como ventiladores
            Reducir el trabajo físicamente exigente, por ejemplo mediante ayudas de elevación
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Cambiar el horario laboral: programar el trabajo pesado para las horas más frescas de la mañana
            Proporcionar pausas adecuadas para enfriarse
            Realizar las tareas pesadas en la sombra o en zonas frescas
            """,
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Para poder avisarte a tiempo sobre niveles peligrosos de calor en tus lugares de trabajo, necesitamos tu permiso para notificaciones push. Permítelas en el siguiente paso.",
            "Stable": "Estable",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "A partir del nivel 2 de alerta por calor (desde 30 °C), deben aplicarse un programa de medidas y medidas de emergencia. Entre las posibles medidas se incluyen:",
            "Stay informed": "Mantente informado",
            "Stop work and move the affected person to shade or a cool place": "Interrumpe el trabajo y lleva a la persona afectada a la sombra o a una sala fresca",
            "System": "Sistema",
            "System language": "Idioma del sistema",
            "Technical measures": "Medidas técnicas",
            "The workplace could not be added.": "No se ha podido añadir el lugar de trabajo.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Esta sesión de la aplicación muestra ahora niveles de alerta aleatorios para todos los lugares de trabajo. El modo se desactiva de nuevo en el próximo reinicio.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Es probable que esta zona esté fuera de Austria o que GeoSphere no la reconozca. No es posible añadirla.",
            "Today": "Hoy",
            "Topics": "Temas",
            "Traffic-light status, UV and workplaces live in one view.": "Estado tipo semáforo, UV y lugares de trabajo en directo en una sola vista.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Índice UV >= 5",
            "UV Protection Measures": "Medidas de protección UV",
            "Unable to add": "No se puede añadir",
            "Warnings": "Advertencias",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Te ayudamos a cumplir los requisitos legales sobre riesgos por calor y radiación UV natural en trabajos al aire libre. Mantén siempre bajo control las temperaturas y el índice UV.",
            "Welcome to Hitze-V": "Bienvenido a Hitze-V",
            "Workplaces": "Lugares de trabajo",
            "Yellow": "Amarillo",
            "n/a": "n/d",
        ],
        .it: [
            "Push notifications": "Notifiche push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Scegli se inviare gli avvisi di calore come notifiche push e per quali luoghi di lavoro.",
            "Enable push notifications": "Attiva le notifiche push",
            "Worksites for push": "Luoghi di lavoro per le notifiche push",
            "Add a worksite first to control push notifications individually.": "Aggiungi prima un luogo di lavoro per gestire le notifiche push singolarmente.",
            "No address available": "Nessun indirizzo disponibile",
            "Turning this off immediately removes all current push subscriptions.": "Disattivando questa opzione vengono rimossi immediatamente tutti gli abbonamenti push attuali.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatura percepita ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatura percepita ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatura percepita ≥ 40 °C)",
            "Active Topic Subscriptions": "Abbonamenti topic attivi",
            "Add": "Aggiungi",
            "Address search failed. Please try again.": "La ricerca dell'indirizzo non è riuscita. Riprova.",
            "Adjust schedules and actively protect teams.": "Adatta gli orari e proteggi attivamente i team.",
            "All clear. Standard precautions are sufficient.": "Tutto tranquillo. Le misure standard sono sufficienti.",
            "All day": "Tutto il giorno",
            "Allow & Start": "Consenti e inizia",
            "Appearance": "Aspetto",
            "Apply Heat-V protective measures immediately.": "Applica subito le misure di protezione Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Con un indice UV pari o superiore a 5, l'esposizione aumenta sensibilmente. Usa sempre indumenti protettivi, copricapo, occhiali da sole e crema solare.",
            "Auto": "Auto",
            "Call 144 now": "Chiama subito il 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Chiama i soccorsi (144) se la condizione non migliora presto o ci sono segni di perdita di coscienza",
            "Cancel": "Annulla",
            "Choose a result": "Scegli un risultato",
            "City, Street...": "Città, via...",
            "Close": "Chiudi",
            "Cool the body, e.g. with damp cloths or ventilation": "Raffredda il corpo con panni umidi, impacchi freddi o ventilazione",
            "Create New Workplace": "Crea nuovo luogo di lavoro",
            "Critical": "Critico",
            "Current Risk": "Rischio attuale",
            "Dark": "Scuro",
            "Data source: GeoSphere Austria": "Fonte dati: GeoSphere Austria",
            "Delete workplace": "Elimina luogo di lavoro",
            "Development": "Sviluppo",
            "Elevated": "Elevato",
            "Emergency measures": "Misure di emergenza",
            "Feels Like": "Temp. percepita",
            "GeoSphere test URL": "URL di test GeoSphere",
            "Green": "Verde",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Mal di testa, vertigini, nausea
            Debolezza, crampi, confusione
            Pelle calda e secca o molto sudata
            Alterazione della coscienza
            """,
            "Heat Protection Measures": "Misure di protezione dal calore",
            "Heat Safety at a Glance": "Sicurezza dal caldo a colpo d'occhio",
            "Heat protection checklist for businesses": "Checklist di protezione dal caldo per le aziende",
            "Heat warning level": "Livello di allerta caldo",
            "Heat warning scale": "Scala di allerta caldo",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "I sintomi legati al caldo possono includere",
            "High": "Alto",
            "If set, this URL is used instead of the GeoSphere server.": "Se impostato, questo URL viene usato al posto del server GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Se non c'è respirazione normale, iniziare subito la rianimazione e chiedere aiuto",
            "If unconscious, place the person in the recovery position": "Se incosciente, mettere la persona in posizione laterale di sicurezza",
            "Increase breaks and shade usage.": "Aumenta le pause e l'uso dell'ombra.",
            "Info": "Info",
            "Info & Legal": "Info e note legali",
            "Label (optional)": "Etichetta (opzionale)",
            "Language": "Lingua",
            "Later / Skip": "Più tardi / Salta",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Far bere lentamente (acqua, tè, soluzioni elettrolitiche)",
            "Light": "Chiaro",
            "Live data could not be loaded right now. Please try again later.": "I dati in tempo reale non possono essere caricati in questo momento. Riprova più tardi.",
            "Loading live data": "Caricamento dati live",
            "Loosen clothing": "Allentare gli indumenti",
            "Maximum values across all workplaces": "Valori massimi di tutti i luoghi di lavoro",
            "Mock active": "Mock attivo",
            "Mock mode enabled": "Modalità mock attivata",
            "Mock mode stays active until the app is restarted.": "La modalità mock resta attiva fino al prossimo riavvio dell'app.",
            "Monitor consciousness and breathing until emergency services arrive": "Controlla coscienza e respirazione fino all'arrivo dei soccorsi e resta con la persona",
            "Monitored Workplaces": "Luoghi di lavoro monitorati",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Sposta, quando possibile, l'esposizione diretta al sole e il lavoro faticoso all'ombra e limita il tempo trascorso in pieno sole.",
            "No active topic subscriptions": "Nessun abbonamento topic attivo",
            "No matching address found.": "Nessun indirizzo corrispondente trovato.",
            "No workplaces yet.": "Nessun luogo di lavoro per ora.",
            "Open info": "Apri info",
            "Optional": "Opzionale",
            "Organizational measures": "Misure organizzative",
            "Peak UV": "Picco UV",
            "Personal protective measures": "Misure di protezione individuale",
            "Please enter an address.": "Inserisci un indirizzo.",
            "Possible emergency measures": "Possibili misure di emergenza",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Fornire acqua potabile a sufficienza
            Abbigliamento da lavoro leggero con protezione UV e crema solare (SPF 50 consigliato), occhiali protettivi UV, panni rinfrescanti
            A seconda dell'ambito di impiego: casco di protezione con protezione per il collo
            """,
            "Quick Glance": "Panoramica rapida",
            "Red": "Rosso",
            "Refresh data": "Aggiorna dati",
            "Response plan (STOP principle)": "Programma di misure (principio STOP)",
            "Search Address": "Cerca indirizzo",
            "Search address or place": "Cerca indirizzo o luogo",
            "Searching address...": "Ricerca indirizzo...",
            "Settings": "Impostazioni",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Ombreggiare aree di lavoro e di pausa con ombrelloni, gazebo, ecc.
            Usare misure tecniche di raffreddamento come ventilatori
            Ridurre il lavoro fisicamente pesante, ad es. con ausili di sollevamento
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Spostare l'orario di lavoro: programmare i lavori pesanti nelle più fresche ore del mattino
            Prevedere pause adeguate per rinfrescarsi
            Svolgere i lavori pesanti all'ombra o in zone fresche
            """,
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Per avvisarti in tempo sui livelli di calore pericolosi nei tuoi luoghi di lavoro, abbiamo bisogno della tua autorizzazione per le notifiche push. Consentile nel passaggio successivo.",
            "Stable": "Stabile",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "A partire dal livello 2 di allerta caldo (da 30 °C), devono essere attuati un programma di misure e misure di emergenza. Le possibili misure includono:",
            "Stay informed": "Resta informato",
            "Stop work and move the affected person to shade or a cool place": "Interrompi il lavoro e porta la persona colpita all'ombra o in una stanza fresca",
            "System": "Sistema",
            "System language": "Lingua di sistema",
            "Technical measures": "Misure tecniche",
            "The workplace could not be added.": "Non è stato possibile aggiungere il luogo di lavoro.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Questa sessione dell'app mostra ora livelli di allerta casuali per tutti i luoghi di lavoro. La modalità si disattiva al prossimo riavvio.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Quest'area è probabilmente fuori dall'Austria o non è riconosciuta da GeoSphere. Non è possibile aggiungerla.",
            "Today": "Oggi",
            "Topics": "Topic",
            "Traffic-light status, UV and workplaces live in one view.": "Stato semaforico, UV e luoghi di lavoro live in un'unica vista.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Indice UV >= 5",
            "UV Protection Measures": "Misure di protezione UV",
            "Unable to add": "Impossibile aggiungere",
            "Warnings": "Avvisi",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ti aiutiamo a rispettare i requisiti legali relativi ai rischi da calore e radiazione UV naturale per il lavoro all'aperto. Tieni sempre sotto controllo temperature e indice UV.",
            "Welcome to Hitze-V": "Benvenuto in Hitze-V",
            "Workplaces": "Luoghi di lavoro",
            "Yellow": "Giallo",
            "n/a": "n/d",
        ],
        .nl: [
            "Push notifications": "Pushmeldingen",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Kies of hittewaarschuwingen als pushmeldingen moeten worden verzonden en voor welke werkplekken.",
            "Enable push notifications": "Pushmeldingen inschakelen",
            "Worksites for push": "Werkplekken voor pushmeldingen",
            "Add a worksite first to control push notifications individually.": "Voeg eerst een werkplek toe om pushmeldingen afzonderlijk te beheren.",
            "No address available": "Geen adres beschikbaar",
            "Turning this off immediately removes all current push subscriptions.": "Als je dit uitschakelt, worden alle huidige pushabonnementen onmiddellijk verwijderd.",
            "2 (apparent temperature ≥ 30 °C)": "2 (gevoelstemperatuur ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (gevoelstemperatuur ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (gevoelstemperatuur ≥ 40 °C)",
            "Active Topic Subscriptions": "Actieve topicabonnementen",
            "Add": "Toevoegen",
            "Address search failed. Please try again.": "Adres zoeken is mislukt. Probeer het opnieuw.",
            "Adjust schedules and actively protect teams.": "Pas roosters aan en bescherm teams actief.",
            "All clear. Standard precautions are sufficient.": "Alles rustig. Standaardmaatregelen zijn voldoende.",
            "All day": "De hele dag",
            "Allow & Start": "Toestaan en starten",
            "Appearance": "Weergave",
            "Apply Heat-V protective measures immediately.": "Voer onmiddellijk Heat-V-beschermingsmaatregelen uit.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Bij UV-index 5 of hoger neemt de belasting duidelijk toe. Gebruik consequent beschermende kleding, hoofdbedekking, zonnebril en zonnebrandcrème.",
            "Auto": "Auto",
            "Call 144 now": "Bel nu 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Bel de hulpdiensten (144) als de toestand niet snel verbetert of er tekenen van bewusteloosheid zijn",
            "Cancel": "Annuleren",
            "Choose a result": "Kies een resultaat",
            "City, Street...": "Plaats, straat...",
            "Close": "Sluiten",
            "Cool the body, e.g. with damp cloths or ventilation": "Koel het lichaam met vochtige doeken, koude kompressen of ventilatie",
            "Create New Workplace": "Nieuwe werkplek aanmaken",
            "Critical": "Kritiek",
            "Current Risk": "Huidig risico",
            "Dark": "Donker",
            "Data source: GeoSphere Austria": "Gegevensbron: GeoSphere Austria",
            "Delete workplace": "Werkplek verwijderen",
            "Development": "Ontwikkeling",
            "Elevated": "Verhoogd",
            "Emergency measures": "Noodmaatregelen",
            "Feels Like": "Gevoelstemp.",
            "GeoSphere test URL": "GeoSphere-test-URL",
            "Green": "Groen",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Hoofdpijn, duizeligheid, misselijkheid
            Zwakte, krampen, verwardheid
            Hete, droge huid of juist zeer zweterige huid
            Bewustzijnsstoornissen
            """,
            "Heat Protection Measures": "Maatregelen tegen hitte",
            "Heat Safety at a Glance": "Hitteveiligheid in één oogopslag",
            "Heat protection checklist for businesses": "Checklist hittebescherming voor bedrijven",
            "Heat warning level": "Hittewaarschuwingsniveau",
            "Heat warning scale": "Schaal voor hittewaarschuwingen",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Hittegerelateerde symptomen kunnen zijn",
            "High": "Hoog",
            "If set, this URL is used instead of the GeoSphere server.": "Als dit is ingesteld, wordt deze URL gebruikt in plaats van de GeoSphere-server.",
            "If there is no normal breathing, start CPR immediately and get help": "Als er geen normale ademhaling is, start dan onmiddellijk met reanimatie en roep hulp in",
            "If unconscious, place the person in the recovery position": "Bij bewusteloosheid: leg de persoon in de stabiele zijligging",
            "Increase breaks and shade usage.": "Verhoog het aantal pauzes en gebruik meer schaduw.",
            "Info": "Info",
            "Info & Legal": "Info en juridisch",
            "Label (optional)": "Label (optioneel)",
            "Language": "Taal",
            "Later / Skip": "Later / Overslaan",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Laat de persoon langzaam drinken (water, thee, elektrolytoplossingen)",
            "Light": "Licht",
            "Live data could not be loaded right now. Please try again later.": "Livegegevens konden momenteel niet worden geladen. Probeer het later opnieuw.",
            "Loading live data": "Livegegevens laden",
            "Loosen clothing": "Kleding losmaken",
            "Maximum values across all workplaces": "Maximale waarden van alle werkplekken",
            "Mock active": "Mock actief",
            "Mock mode enabled": "Mockmodus ingeschakeld",
            "Mock mode stays active until the app is restarted.": "De mockmodus blijft actief tot de app opnieuw wordt gestart.",
            "Monitor consciousness and breathing until emergency services arrive": "Controleer bewustzijn en ademhaling tot de hulpdiensten arriveren en blijf bij de persoon",
            "Monitored Workplaces": "Bewaakte werkplekken",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Verplaats directe zonblootstelling en zwaar werk waar mogelijk naar de schaduw en beperk de tijd in de volle zon.",
            "No active topic subscriptions": "Geen actieve topicabonnementen",
            "No matching address found.": "Geen passend adres gevonden.",
            "No workplaces yet.": "Nog geen werkplekken.",
            "Open info": "Info openen",
            "Optional": "Optioneel",
            "Organizational measures": "Organisatorische maatregelen",
            "Peak UV": "Piek-UV",
            "Personal protective measures": "Persoonlijke beschermingsmaatregelen",
            "Please enter an address.": "Voer een adres in.",
            "Possible emergency measures": "Mogelijke noodmaatregelen",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Voldoende drinkwater beschikbaar stellen
            Lichte werkkleding met UV-bescherming en zonnebrandcrème (SPF 50 aanbevolen), UV-beschermende bril, koeldoeken
            Afhankelijk van het werkgebied: veiligheidshelm met nekbescherming
            """,
            "Quick Glance": "Snel overzicht",
            "Red": "Rood",
            "Refresh data": "Gegevens vernieuwen",
            "Response plan (STOP principle)": "Maatregelenprogramma (STOP-principe)",
            "Search Address": "Adres zoeken",
            "Search address or place": "Adres of plaats zoeken",
            "Searching address...": "Adres wordt gezocht...",
            "Settings": "Instellingen",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Schaduw creëren op werk- en rustplaatsen met (mobiele) parasols, partytenten enz.
            Technische koelmaatregelen inzetten, zoals ventilatoren
            Fysiek zwaar werk verminderen, bijvoorbeeld met tilhulpen
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Werktijden verschuiven: plan zwaar werk in de koelere ochtenduren
            Zorg voor voldoende afkoelpauzes
            Voer zware taken uit in de schaduw of in koele zones
            """,
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "Om je op tijd te waarschuwen voor gevaarlijke hitteniveaus op je werkplekken, hebben we toestemming nodig voor pushmeldingen. Sta die toe in de volgende stap.",
            "Stable": "Stabiel",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Vanaf hittewaarschuwingsniveau 2 (vanaf 30 °C) moeten een maatregelenprogramma en noodmaatregelen worden uitgevoerd. Mogelijke maatregelen zijn onder meer:",
            "Stay informed": "Blijf geïnformeerd",
            "Stop work and move the affected person to shade or a cool place": "Stop het werk en breng de getroffen persoon naar de schaduw of een koele ruimte",
            "System": "Systeem",
            "System language": "Systeemtaal",
            "Technical measures": "Technische maatregelen",
            "The workplace could not be added.": "De werkplek kon niet worden toegevoegd.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Deze appsessie toont nu willekeurige waarschuwingsniveaus voor alle werkplekken. De modus wordt bij de volgende herstart weer uitgeschakeld.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Dit gebied ligt waarschijnlijk buiten Oostenrijk of wordt niet herkend door GeoSphere. Toevoegen is niet mogelijk.",
            "Today": "Vandaag",
            "Topics": "Topics",
            "Traffic-light status, UV and workplaces live in one view.": "Stoplichtstatus, UV en werkplekken live in één overzicht.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-index >= 5",
            "UV Protection Measures": "UV-beschermingsmaatregelen",
            "Unable to add": "Toevoegen niet mogelijk",
            "Warnings": "Waarschuwingen",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "We helpen je te voldoen aan wettelijke eisen rond risico's door hitte en natuurlijke UV-straling bij buitenwerk. Houd temperaturen en UV-index altijd in de gaten.",
            "Welcome to Hitze-V": "Welkom bij Hitze-V",
            "Workplaces": "Werkplekken",
            "Yellow": "Geel",
            "n/a": "n.v.t.",
        ],
        .sv: [
            "Push notifications": "Pushnotiser",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Välj om värmevarningar ska skickas som pushnotiser och för vilka arbetsplatser.",
            "Enable push notifications": "Aktivera pushnotiser",
            "Worksites for push": "Arbetsplatser för pushnotiser",
            "Add a worksite first to control push notifications individually.": "Lägg först till en arbetsplats för att styra pushnotiser individuellt.",
            "No address available": "Ingen adress tillgänglig",
            "Turning this off immediately removes all current push subscriptions.": "Om du stänger av detta tas alla nuvarande pushprenumerationer bort direkt.",
            "2 (apparent temperature ≥ 30 °C)": "2 (upplevd temperatur ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (upplevd temperatur ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (upplevd temperatur ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktiva ämnesprenumerationer",
            "Add": "Lägg till",
            "Address search failed. Please try again.": "Adressökningen misslyckades. Försök igen.",
            "Adjust schedules and actively protect teams.": "Anpassa scheman och skydda teamen aktivt.",
            "All clear. Standard precautions are sufficient.": "Allt lugnt. Standardåtgärder räcker.",
            "All day": "Hela dagen",
            "Allow & Start": "Tillåt och starta",
            "Appearance": "Utseende",
            "Apply Heat-V protective measures immediately.": "Genomför Heat-V-skyddsåtgärder omedelbart.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Vid UV-index 5 och högre ökar belastningen tydligt. Använd konsekvent skyddskläder, huvudskydd, solglasögon och solskydd.",
            "Auto": "Auto",
            "Call 144 now": "Ring 144 nu",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Ring räddningstjänsten (144) om tillståndet inte förbättras snart eller om det finns tecken på medvetslöshet",
            "Cancel": "Avbryt",
            "Choose a result": "Välj ett resultat",
            "City, Street...": "Stad, gata...",
            "Close": "Stäng",
            "Cool the body, e.g. with damp cloths or ventilation": "Kyl kroppen med fuktiga handdukar, kalla kompresser eller ventilation",
            "Create New Workplace": "Skapa ny arbetsplats",
            "Critical": "Kritisk",
            "Current Risk": "Aktuell risk",
            "Dark": "Mörk",
            "Data source: GeoSphere Austria": "Datakälla: GeoSphere Austria",
            "Delete workplace": "Ta bort arbetsplats",
            "Development": "Utveckling",
            "Elevated": "Förhöjd",
            "Emergency measures": "Akutåtgärder",
            "Feels Like": "Känns som",
            "GeoSphere test URL": "GeoSphere-test-URL",
            "Green": "Grön",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Huvudvärk, yrsel, illamående
            Svaghet, kramper, förvirring
            Het, torr hud eller mycket svettig hud
            Nedsatt medvetande
            """,
            "Heat Protection Measures": "Värmeskyddsåtgärder",
            "Heat Safety at a Glance": "Värmesäkerhet i ett ögonkast",
            "Heat protection checklist for businesses": "Checklista för värmeskydd för företag",
            "Heat warning level": "Värmevarningsnivå",
            "Heat warning scale": "Skala för värmevarningar",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Värmerelaterade symtom kan omfatta",
            "High": "Hög",
            "If set, this URL is used instead of the GeoSphere server.": "Om inställd används denna URL i stället för GeoSphere-servern.",
            "If there is no normal breathing, start CPR immediately and get help": "Om normal andning saknas, påbörja HLR omedelbart och kalla på hjälp",
            "If unconscious, place the person in the recovery position": "Vid medvetslöshet, lägg personen i stabilt sidoläge",
            "Increase breaks and shade usage.": "Öka pauserna och använd skugga mer.",
            "Info": "Info",
            "Info & Legal": "Info och juridik",
            "Label (optional)": "Etikett (valfritt)",
            "Language": "Språk",
            "Later / Skip": "Senare / Hoppa över",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Låt personen dricka långsamt (vatten, te, elektrolytlösningar)",
            "Light": "Ljus",
            "Live data could not be loaded right now. Please try again later.": "Livedata kunde inte laddas just nu. Försök igen senare.",
            "Loading live data": "Laddar livedata",
            "Loosen clothing": "Lossa kläderna",
            "Maximum values across all workplaces": "Maxvärden över alla arbetsplatser",
            "Mock active": "Mock aktiv",
            "Mock mode enabled": "Mockläge aktiverat",
            "Mock mode stays active until the app is restarted.": "Mockläget förblir aktivt tills appen startas om.",
            "Monitor consciousness and breathing until emergency services arrive": "Kontrollera medvetande och andning tills räddningstjänsten anländer och stanna hos personen",
            "Monitored Workplaces": "Övervakade arbetsplatser",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Flytta direkt solljus och ansträngande arbete till skugga när det är möjligt och begränsa tiden i full sol.",
            "No active topic subscriptions": "Inga aktiva ämnesprenumerationer",
            "No matching address found.": "Ingen passande adress hittades.",
            "No workplaces yet.": "Inga arbetsplatser ännu.",
            "Open info": "Öppna info",
            "Optional": "Valfritt",
            "Organizational measures": "Organisatoriska åtgärder",
            "Peak UV": "Högsta UV",
            "Personal protective measures": "Personliga skyddsåtgärder",
            "Please enter an address.": "Ange en adress.",
            "Possible emergency measures": "Möjliga akutåtgärder",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Tillhandahåll tillräckligt med dricksvatten
            Lätta arbetskläder med UV-skydd och solskyddsmedel (SPF 50 rekommenderas), UV-skyddsglasögon, kylhanddukar
            Beroende på arbetsområde: skyddshjälm med nackskydd
            """,
            "Quick Glance": "Snabböversikt",
            "Red": "Röd",
            "Refresh data": "Uppdatera data",
            "Response plan (STOP principle)": "Åtgärdsprogram (STOP-principen)",
            "Search Address": "Sök adress",
            "Search address or place": "Sök adress eller plats",
            "Searching address...": "Söker adress...",
            "Settings": "Inställningar",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Skugga arbets- och viloplatser med (mobila) parasoller, paviljonger etc.
            Använd tekniska kylåtgärder såsom fläktar
            Minska fysiskt ansträngande arbete, t.ex. genom lyfthjälpmedel
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Flytta arbetstider: lägg tungt arbete till svalare morgontimmar
            Ge lämpliga pauser för nedkylning
            Utför tunga uppgifter i skugga eller svala områden
            """,
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step.": "För att vi ska kunna varna dig i tid om farliga värmenivåer på dina arbetsplatser behöver vi ditt tillstånd för pushnotiser. Tillåt dem i nästa steg.",
            "Stable": "Stabil",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Från värmevarningsnivå 2 (från 30 °C) måste ett åtgärdsprogram och nödfallsåtgärder genomföras. Möjliga åtgärder är bland annat:",
            "Stay informed": "Håll dig informerad",
            "Stop work and move the affected person to shade or a cool place": "Avbryt arbetet och flytta den drabbade personen till skugga eller ett svalt rum",
            "System": "System",
            "System language": "Systemspråk",
            "Technical measures": "Tekniska åtgärder",
            "The workplace could not be added.": "Arbetsplatsen kunde inte läggas till.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Den här appsessionen visar nu slumpmässiga varningsnivåer för alla arbetsplatser. Läget stängs av igen vid nästa omstart.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Det här området ligger troligen utanför Österrike eller känns inte igen av GeoSphere. Det går inte att lägga till.",
            "Today": "I dag",
            "Topics": "Ämnen",
            "Traffic-light status, UV and workplaces live in one view.": "Trafikljusstatus, UV och arbetsplatser live i en och samma vy.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-index >= 5",
            "UV Protection Measures": "UV-skyddsåtgärder",
            "Unable to add": "Kan inte lägga till",
            "Warnings": "Varningar",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Vi hjälper dig att uppfylla lagkrav kring risker från värme och naturlig UV-strålning vid utomhusarbete. Håll alltid koll på temperaturer och UV-index.",
            "Welcome to Hitze-V": "Välkommen till Hitze-V",
            "Workplaces": "Arbetsplatser",
            "Yellow": "Gul",
            "n/a": "ej tillg.",
        ],
        .pt: [
            "Push notifications": "Notificações push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Escolha se os alertas de calor devem ser enviados como notificações push e para quais locais de trabalho.",
            "Enable push notifications": "Ativar notificações push",
            "Worksites for push": "Locais de trabalho para notificações push",
            "Add a worksite first to control push notifications individually.": "Adicione primeiro um local de trabalho para gerir as notificações push individualmente.",
            "No address available": "Sem endereço disponível",
            "Turning this off immediately removes all current push subscriptions.": "Ao desativar isto, todas as subscrições push atuais são removidas imediatamente.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatura aparente ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatura aparente ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatura aparente ≥ 40 °C)",
            "Active Topic Subscriptions": "Subscrições ativas de tópicos",
            "Add": "Adicionar",
            "Address search failed. Please try again.": "A pesquisa de endereço falhou. Tente novamente.",
            "Adjust schedules and actively protect teams.": "Ajuste os horários e proteja ativamente as equipas.",
            "All clear. Standard precautions are sufficient.": "Tudo está estável. As precauções padrão são suficientes.",
            "All day": "Todo o dia",
            "Allow & Start": "Permitir e começar",
            "Appearance": "Aspeto",
            "Apply Heat-V protective measures immediately.": "Aplique imediatamente as medidas de proteção Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Com índice UV 5 ou superior, a exposição aumenta significativamente. Use de forma consistente roupa de proteção, cobertura para a cabeça, óculos de sol e protetor solar.",
            "Auto": "Auto",
            "Call 144 now": "Ligar já para o 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Ligue para os serviços de emergência (144) se o estado não melhorar rapidamente ou houver sinais de perda de consciência",
            "Cancel": "Cancelar",
            "Choose a result": "Escolha um resultado",
            "City, Street...": "Cidade, rua...",
            "Close": "Fechar",
            "Cool the body, e.g. with damp cloths or ventilation": "Arrefeça o corpo com panos húmidos, compressas frias ou ventilação",
            "Create New Workplace": "Criar novo local de trabalho",
            "Critical": "Crítico",
            "Current Risk": "Risco atual",
            "Dark": "Escuro",
            "Data source: GeoSphere Austria": "Fonte de dados: GeoSphere Austria",
            "Delete workplace": "Eliminar local de trabalho",
            "Development": "Desenvolvimento",
            "Elevated": "Elevado",
            "Emergency measures": "Medidas de emergência",
            "Feels Like": "Sensação térmica",
            "GeoSphere test URL": "URL de teste GeoSphere",
            "Green": "Verde",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Dores de cabeça, tonturas, náuseas
            Fraqueza, cãibras, confusão
            Pele quente e seca ou pele muito suada
            Consciência comprometida
            """,
            "Heat Protection Measures": "Medidas de proteção contra o calor",
            "Heat Safety at a Glance": "Segurança térmica num relance",
            "Heat protection checklist for businesses": "Lista de verificação de proteção contra o calor para empresas",
            "Heat warning level": "Nível de aviso de calor",
            "Heat warning scale": "Escala de aviso de calor",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Os sintomas relacionados com o calor podem incluir",
            "High": "Alto",
            "If set, this URL is used instead of the GeoSphere server.": "Se definida, esta URL é usada em vez do servidor GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Se não houver respiração normal, inicie imediatamente a reanimação e peça ajuda",
            "If unconscious, place the person in the recovery position": "Se a pessoa estiver inconsciente, coloque-a na posição lateral de segurança",
            "Increase breaks and shade usage.": "Aumente as pausas e o uso de sombra.",
            "Info": "Informação",
            "Info & Legal": "Informação e legal",
            "Label (optional)": "Etiqueta (opcional)",
            "Later / Skip": "Mais tarde / Ignorar",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Deixe a pessoa beber lentamente (água, chá, soluções eletrolíticas)",
            "Light": "Claro",
            "Live data could not be loaded right now. Please try again later.": "Não foi possível carregar os dados em direto neste momento. Tente novamente mais tarde.",
            "Loading live data": "A carregar dados em direto",
            "Loosen clothing": "Afrouxar a roupa",
            "Maximum values across all workplaces": "Valores máximos em todos os locais de trabalho",
            "Mock active": "Mock ativo",
            "Mock mode enabled": "Modo mock ativado",
            "Mock mode stays active until the app is restarted.": "O modo mock permanece ativo até a aplicação ser reiniciada.",
            "Monitor consciousness and breathing until emergency services arrive": "Monitorize a consciência e a respiração até chegarem os serviços de emergência e permaneça com a pessoa",
            "Monitored Workplaces": "Locais de trabalho monitorizados",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Sempre que possível, desloque a exposição direta ao sol e o trabalho exigente para a sombra e limite o tempo passado sob sol intenso.",
            "No active topic subscriptions": "Sem subscrições ativas de tópicos",
            "No matching address found.": "Não foi encontrado nenhum endereço correspondente.",
            "No workplaces yet.": "Ainda não existem locais de trabalho.",
            "Open info": "Abrir informação",
            "Optional": "Opcional",
            "Organizational measures": "Medidas organizacionais",
            "Peak UV": "Pico UV",
            "Personal protective measures": "Medidas de proteção individual",
            "Please enter an address.": "Introduza um endereço.",
            "Possible emergency measures": "Possíveis medidas de emergência",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Disponibilizar água potável suficiente
            Roupa de trabalho leve com proteção UV e protetor solar (FPS 50 recomendado), óculos com proteção UV, toalhas refrescantes
            Consoante a área de trabalho: capacete de proteção com proteção para a nuca
            """,
            "Quick Glance": "Vista rápida",
            "Red": "Vermelho",
            "Refresh data": "Atualizar dados",
            "Response plan (STOP principle)": "Plano de resposta (princípio STOP)",
            "Search Address": "Pesquisar endereço",
            "Search address or place": "Pesquisar endereço ou local",
            "Searching address...": "A pesquisar endereço...",
            "Settings": "Definições",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Criar sombra nas áreas de trabalho e de descanso com guarda-sóis (móveis), pavilhões, etc.
            Utilizar medidas técnicas de arrefecimento, como ventoinhas
            Reduzir o trabalho fisicamente exigente, por exemplo com meios de elevação
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Alterar os horários de trabalho: programar as tarefas pesadas para as horas matinais mais frescas
            Proporcionar pausas adequadas para arrefecimento
            Executar tarefas pesadas à sombra ou em áreas frescas
            """,
            "Stable": "Estável",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "A partir do nível de aviso de calor 2 (a partir de 30 °C), deve ser implementado um plano de resposta e medidas de emergência. As medidas possíveis incluem:",
            "Stay informed": "Mantenha-se informado",
            "Stop work and move the affected person to shade or a cool place": "Pare o trabalho e leve a pessoa afetada para a sombra ou para uma sala fresca",
            "System": "Sistema",
            "System language": "Idioma do sistema",
            "Technical measures": "Medidas técnicas",
            "The workplace could not be added.": "Não foi possível adicionar o local de trabalho.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Esta sessão da aplicação mostra agora níveis de aviso aleatórios para todos os locais de trabalho. O modo volta a desligar-se no próximo reinício.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "É provável que esta área esteja fora da Áustria ou não seja reconhecida pela GeoSphere. Não é possível adicionar.",
            "Today": "Hoje",
            "Topics": "Tópicos",
            "Traffic-light status, UV and workplaces live in one view.": "Estado semafórico, UV e locais de trabalho em direto numa só vista.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Índice UV >= 5",
            "UV Protection Measures": "Medidas de proteção UV",
            "Unable to add": "Não foi possível adicionar",
            "Warnings": "Avisos",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ajudamos a cumprir os requisitos legais relativos aos perigos do calor e da radiação UV natural no trabalho ao ar livre. Acompanhe sempre as temperaturas e o índice UV.",
            "Welcome to Hitze-V": "Bem-vindo ao Hitze-V",
            "Workplaces": "Locais de trabalho",
            "Yellow": "Amarelo",
            "n/a": "n/d",
        ],
        .ro: [
            "Push notifications": "Notificări push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Alege dacă alertele de căldură trebuie trimise ca notificări push și pentru ce locuri de muncă.",
            "Enable push notifications": "Activează notificările push",
            "Worksites for push": "Locuri de muncă pentru notificări push",
            "Add a worksite first to control push notifications individually.": "Adaugă mai întâi un loc de muncă pentru a gestiona individual notificările push.",
            "No address available": "Nicio adresă disponibilă",
            "Turning this off immediately removes all current push subscriptions.": "Dezactivarea acestei opțiuni elimină imediat toate abonamentele push curente.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatură resimțită ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatură resimțită ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatură resimțită ≥ 40 °C)",
            "Active Topic Subscriptions": "Abonamente active la subiecte",
            "Add": "Adaugă",
            "Address search failed. Please try again.": "Căutarea adresei a eșuat. Încearcă din nou.",
            "Adjust schedules and actively protect teams.": "Ajustează programul și protejează activ echipele.",
            "All clear. Standard precautions are sufficient.": "Totul este în regulă. Măsurile standard sunt suficiente.",
            "All day": "Toată ziua",
            "Allow & Start": "Permite și începe",
            "Appearance": "Aspect",
            "Apply Heat-V protective measures immediately.": "Aplică imediat măsurile de protecție Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "La un indice UV de 5 sau mai mare, expunerea crește semnificativ. Folosește constant îmbrăcăminte de protecție, acoperământ pentru cap, ochelari de soare și cremă de protecție solară.",
            "Auto": "Auto",
            "Call 144 now": "Sună acum la 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Sună la serviciile de urgență (144) dacă starea nu se îmbunătățește curând sau există semne de pierdere a cunoștinței",
            "Cancel": "Anulează",
            "Choose a result": "Alege un rezultat",
            "City, Street...": "Oraș, stradă...",
            "Close": "Închide",
            "Cool the body, e.g. with damp cloths or ventilation": "Răcește corpul cu cârpe umede, comprese reci sau ventilație",
            "Create New Workplace": "Creează un nou loc de muncă",
            "Critical": "Critic",
            "Current Risk": "Risc actual",
            "Dark": "Întunecat",
            "Data source: GeoSphere Austria": "Sursa datelor: GeoSphere Austria",
            "Delete workplace": "Șterge locul de muncă",
            "Development": "Dezvoltare",
            "Elevated": "Ridicat",
            "Emergency measures": "Măsuri de urgență",
            "Feels Like": "Temperatură resimțită",
            "GeoSphere test URL": "URL de test GeoSphere",
            "Green": "Verde",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Dureri de cap, amețeli, greață
            Slăbiciune, crampe, confuzie
            Piele fierbinte și uscată sau piele foarte transpirată
            Conștiință afectată
            """,
            "Heat Protection Measures": "Măsuri de protecție împotriva căldurii",
            "Heat Safety at a Glance": "Siguranța la căldură dintr-o privire",
            "Heat protection checklist for businesses": "Listă de verificare pentru protecția împotriva căldurii pentru companii",
            "Heat warning level": "Nivel de avertizare de căldură",
            "Heat warning scale": "Scara avertizărilor de căldură",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Simptomele legate de căldură pot include",
            "High": "Ridicat",
            "If set, this URL is used instead of the GeoSphere server.": "Dacă este setat, acest URL este folosit în locul serverului GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Dacă nu există respirație normală, începe imediat resuscitarea și cere ajutor",
            "If unconscious, place the person in the recovery position": "Dacă persoana este inconștientă, așaz-o în poziția laterală de siguranță",
            "Increase breaks and shade usage.": "Mărește numărul pauzelor și folosirea umbrei.",
            "Info": "Informații",
            "Info & Legal": "Informații și aspecte legale",
            "Label (optional)": "Etichetă (opțional)",
            "Later / Skip": "Mai târziu / Omite",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Lasă persoana să bea încet (apă, ceai, soluții electrolitice)",
            "Light": "Luminos",
            "Live data could not be loaded right now. Please try again later.": "Datele live nu pot fi încărcate acum. Încearcă din nou mai târziu.",
            "Loading live data": "Se încarcă datele live",
            "Loosen clothing": "Slăbește hainele",
            "Maximum values across all workplaces": "Valorile maxime din toate locurile de muncă",
            "Mock active": "Mock activ",
            "Mock mode enabled": "Mod mock activat",
            "Mock mode stays active until the app is restarted.": "Modul mock rămâne activ până la repornirea aplicației.",
            "Monitor consciousness and breathing until emergency services arrive": "Monitorizează starea de conștiență și respirația până la sosirea serviciilor de urgență și rămâi cu persoana",
            "Monitored Workplaces": "Locuri de muncă monitorizate",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Mută, ori de câte ori este posibil, expunerea directă la soare și munca solicitantă la umbră și limitează timpul petrecut în soare puternic.",
            "No active topic subscriptions": "Nu există abonamente active la subiecte",
            "No matching address found.": "Nu a fost găsită nicio adresă potrivită.",
            "No workplaces yet.": "Încă nu există locuri de muncă.",
            "Open info": "Deschide informațiile",
            "Optional": "Opțional",
            "Organizational measures": "Măsuri organizatorice",
            "Peak UV": "Vârf UV",
            "Personal protective measures": "Măsuri de protecție personală",
            "Please enter an address.": "Introdu o adresă.",
            "Possible emergency measures": "Posibile măsuri de urgență",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Asigură suficientă apă potabilă
            Îmbrăcăminte de lucru ușoară cu protecție UV și cremă de protecție solară (SPF 50 recomandat), ochelari cu protecție UV, prosoape răcoritoare
            În funcție de domeniul de activitate: cască de protecție cu protecție pentru ceafă
            """,
            "Quick Glance": "Privire rapidă",
            "Red": "Roșu",
            "Refresh data": "Reîmprospătează datele",
            "Response plan (STOP principle)": "Plan de răspuns (principiul STOP)",
            "Search Address": "Caută adresă",
            "Search address or place": "Caută adresă sau loc",
            "Searching address...": "Se caută adresa...",
            "Settings": "Setări",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Umbriți zonele de lucru și de odihnă cu umbrele (mobile), pavilioane etc.
            Folosiți măsuri tehnice de răcire, cum ar fi ventilatoarele
            Reduceți munca fizic solicitantă, de exemplu prin folosirea mijloacelor de ridicare
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Modificați programul de lucru: programați munca grea pentru orele răcoroase ale dimineții
            Oferiți pauze adecvate pentru răcorire
            Efectuați sarcinile grele la umbră sau în zone răcoroase
            """,
            "Stable": "Stabil",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Începând cu nivelul 2 de avertizare de căldură (de la 30 °C), trebuie implementat un plan de răspuns și măsuri de urgență. Măsurile posibile includ:",
            "Stay informed": "Rămâi informat",
            "Stop work and move the affected person to shade or a cool place": "Oprește munca și mută persoana afectată la umbră sau într-o încăpere răcoroasă",
            "System": "Sistem",
            "System language": "Limba sistemului",
            "Technical measures": "Măsuri tehnice",
            "The workplace could not be added.": "Locul de muncă nu a putut fi adăugat.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Această sesiune a aplicației afișează acum niveluri de avertizare aleatorii pentru toate locurile de muncă. Modul se dezactivează din nou la următoarea repornire.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Această zonă este probabil în afara Austriei sau nu este recunoscută de GeoSphere. Adăugarea nu este posibilă.",
            "Today": "Astăzi",
            "Topics": "Subiecte",
            "Traffic-light status, UV and workplaces live in one view.": "Starea semaforului, UV și locurile de muncă live într-o singură vedere.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Indice UV >= 5",
            "UV Protection Measures": "Măsuri de protecție UV",
            "Unable to add": "Nu se poate adăuga",
            "Warnings": "Avertizări",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Te ajutăm să respecți cerințele legale privind riscurile de căldură și radiație UV naturală la munca în aer liber. Urmărește permanent temperaturile și indicele UV.",
            "Welcome to Hitze-V": "Bine ai venit la Hitze-V",
            "Workplaces": "Locuri de muncă",
            "Yellow": "Galben",
            "n/a": "n/d",
        ],
        .hr: [
            "Push notifications": "Push obavijesti",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Odaberite hoće li se upozorenja na vrućinu slati kao push obavijesti i za koja radna mjesta.",
            "Enable push notifications": "Omogući push obavijesti",
            "Worksites for push": "Radna mjesta za push obavijesti",
            "Add a worksite first to control push notifications individually.": "Najprije dodajte radno mjesto kako biste pojedinačno upravljali push obavijestima.",
            "No address available": "Adresa nije dostupna",
            "Turning this off immediately removes all current push subscriptions.": "Isključivanje ove postavke odmah uklanja sve trenutačne push pretplate.",
            "2 (apparent temperature ≥ 30 °C)": "2 (osjetna temperatura ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (osjetna temperatura ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (osjetna temperatura ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktivne pretplate na teme",
            "Add": "Dodaj",
            "Address search failed. Please try again.": "Pretraživanje adrese nije uspjelo. Pokušajte ponovno.",
            "Adjust schedules and actively protect teams.": "Prilagodite rasporede i aktivno zaštitite timove.",
            "All clear. Standard precautions are sufficient.": "Sve je u redu. Standardne mjere opreza su dovoljne.",
            "All day": "Cijeli dan",
            "Allow & Start": "Dopusti i pokreni",
            "Appearance": "Izgled",
            "Apply Heat-V protective measures immediately.": "Odmah primijenite zaštitne mjere Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Pri UV indeksu 5 i višem izloženost se znatno povećava. Dosljedno koristite zaštitnu odjeću, pokrivalo za glavu, sunčane naočale i kremu za sunčanje.",
            "Auto": "Auto",
            "Call 144 now": "Nazovite 144 odmah",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Nazovite hitne službe (144) ako se stanje uskoro ne poboljša ili postoje znakovi gubitka svijesti",
            "Cancel": "Odustani",
            "Choose a result": "Odaberite rezultat",
            "City, Street...": "Grad, ulica...",
            "Close": "Zatvori",
            "Cool the body, e.g. with damp cloths or ventilation": "Rashladite tijelo vlažnim krpama, hladnim oblozima ili ventilacijom",
            "Create New Workplace": "Stvori novo radno mjesto",
            "Critical": "Kritično",
            "Current Risk": "Trenutačni rizik",
            "Dark": "Tamno",
            "Data source: GeoSphere Austria": "Izvor podataka: GeoSphere Austria",
            "Delete workplace": "Izbriši radno mjesto",
            "Development": "Razvoj",
            "Elevated": "Povišeno",
            "Emergency measures": "Hitne mjere",
            "Feels Like": "Osjetna temperatura",
            "GeoSphere test URL": "GeoSphere testni URL",
            "Green": "Zeleno",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Glavobolja, vrtoglavica, mučnina
            Slabost, grčevi, zbunjenost
            Vruća, suha koža ili jako znojna koža
            Poremećena svijest
            """,
            "Heat Protection Measures": "Mjere zaštite od vrućine",
            "Heat Safety at a Glance": "Sigurnost pri vrućini na prvi pogled",
            "Heat protection checklist for businesses": "Kontrolni popis zaštite od vrućine za poduzeća",
            "Heat warning level": "Razina upozorenja na vrućinu",
            "Heat warning scale": "Skala upozorenja na vrućinu",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Simptomi povezani s vrućinom mogu uključivati",
            "High": "Visoko",
            "If set, this URL is used instead of the GeoSphere server.": "Ako je postavljen, ovaj URL koristi se umjesto GeoSphere poslužitelja.",
            "If there is no normal breathing, start CPR immediately and get help": "Ako nema normalnog disanja, odmah započnite reanimaciju i pozovite pomoć",
            "If unconscious, place the person in the recovery position": "Ako je osoba bez svijesti, stavite je u bočni položaj",
            "Increase breaks and shade usage.": "Povećajte broj pauza i korištenje hlada.",
            "Info": "Info",
            "Info & Legal": "Informacije i pravno",
            "Label (optional)": "Oznaka (neobavezno)",
            "Later / Skip": "Kasnije / Preskoči",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Pustite osobu da polako pije (vodu, čaj, otopine elektrolita)",
            "Light": "Svijetlo",
            "Live data could not be loaded right now. Please try again later.": "Podaci uživo trenutno se ne mogu učitati. Pokušajte ponovno kasnije.",
            "Loading live data": "Učitavanje podataka uživo",
            "Loosen clothing": "Otpustite odjeću",
            "Maximum values across all workplaces": "Maksimalne vrijednosti na svim radnim mjestima",
            "Mock active": "Mock aktivan",
            "Mock mode enabled": "Mock način rada uključen",
            "Mock mode stays active until the app is restarted.": "Mock način rada ostaje aktivan do ponovnog pokretanja aplikacije.",
            "Monitor consciousness and breathing until emergency services arrive": "Pratite svijest i disanje do dolaska hitne pomoći i ostanite s osobom",
            "Monitored Workplaces": "Praćena radna mjesta",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Kad god je moguće, premjestite izravno izlaganje suncu i naporan rad u hlad te ograničite vrijeme provedeno na jakom suncu.",
            "No active topic subscriptions": "Nema aktivnih pretplata na teme",
            "No matching address found.": "Nije pronađena odgovarajuća adresa.",
            "No workplaces yet.": "Još nema radnih mjesta.",
            "Open info": "Otvori informacije",
            "Optional": "Neobavezno",
            "Organizational measures": "Organizacijske mjere",
            "Peak UV": "Najviši UV",
            "Personal protective measures": "Osobne zaštitne mjere",
            "Please enter an address.": "Unesite adresu.",
            "Possible emergency measures": "Moguće hitne mjere",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Osigurajte dovoljno pitke vode
            Lagana radna odjeća s UV zaštitom i sredstvom za sunčanje (preporučuje se SPF 50), UV zaštitne naočale, rashladni ručnici
            Ovisno o području rada: zaštitna kaciga sa zaštitom za vrat
            """,
            "Quick Glance": "Brzi pregled",
            "Red": "Crveno",
            "Refresh data": "Osvježi podatke",
            "Response plan (STOP principle)": "Plan mjera (STOP načelo)",
            "Search Address": "Pretraži adresu",
            "Search address or place": "Pretraži adresu ili mjesto",
            "Searching address...": "Pretraživanje adrese...",
            "Settings": "Postavke",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Zasjenite radna i odmorišna mjesta (mobilnim) suncobranima, paviljonima itd.
            Koristite tehničke mjere hlađenja kao što su ventilatori
            Smanjite fizički naporan rad, npr. uporabom pomagala za dizanje
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Pomaknite radno vrijeme: teške poslove planirajte u hladnije jutarnje sate
            Osigurajte odgovarajuće pauze za rashlađivanje
            Teške zadatke obavljajte u hladu ili na hladnim mjestima
            """,
            "Stable": "Stabilno",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Od razine upozorenja na vrućinu 2 (od 30 °C) moraju se provoditi plan mjera i hitne mjere. Moguće mjere uključuju:",
            "Stay informed": "Budite informirani",
            "Stop work and move the affected person to shade or a cool place": "Prekinite rad i premjestite pogođenu osobu u hlad ili u hladnu prostoriju",
            "System": "Sustav",
            "System language": "Jezik sustava",
            "Technical measures": "Tehničke mjere",
            "The workplace could not be added.": "Radno mjesto nije moglo biti dodano.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Ova sesija aplikacije sada prikazuje nasumične razine upozorenja za sva radilišta. Način rada se ponovno isključuje pri sljedećem pokretanju.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Ovo je područje vjerojatno izvan Austrije ili ga GeoSphere ne prepoznaje. Dodavanje nije moguće.",
            "Today": "Danas",
            "Topics": "Teme",
            "Traffic-light status, UV and workplaces live in one view.": "Semaforski status, UV i radna mjesta uživo u jednom prikazu.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV indeks >= 5",
            "UV Protection Measures": "Mjere UV zaštite",
            "Unable to add": "Nije moguće dodati",
            "Warnings": "Upozorenja",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomažemo vam uskladiti se sa zakonskim zahtjevima vezanim uz opasnosti od vrućine i prirodnog UV zračenja pri radu na otvorenom. Uvijek pratite temperaturu i UV indeks.",
            "Welcome to Hitze-V": "Dobro došli u Hitze-V",
            "Workplaces": "Radna mjesta",
            "Yellow": "Žuto",
            "n/a": "n/p",
        ],
        .sl: [
            "Push notifications": "Push obvestila",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Izberite, ali naj se opozorila o vročini pošiljajo kot push obvestila in za katera delovna mesta.",
            "Enable push notifications": "Omogoči push obvestila",
            "Worksites for push": "Delovna mesta za push obvestila",
            "Add a worksite first to control push notifications individually.": "Najprej dodajte delovno mesto, da boste lahko push obvestila upravljali posamezno.",
            "No address available": "Naslov ni na voljo",
            "Turning this off immediately removes all current push subscriptions.": "Če to izklopite, se vse trenutne push naročnine takoj odstranijo.",
            "2 (apparent temperature ≥ 30 °C)": "2 (občutena temperatura ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (občutena temperatura ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (občutena temperatura ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktivne naročnine na teme",
            "Add": "Dodaj",
            "Address search failed. Please try again.": "Iskanje naslova ni uspelo. Poskusite znova.",
            "Adjust schedules and actively protect teams.": "Prilagodite urnike in aktivno zaščitite ekipe.",
            "All clear. Standard precautions are sufficient.": "Vse je v redu. Standardni previdnostni ukrepi zadostujejo.",
            "All day": "Cel dan",
            "Allow & Start": "Dovoli in začni",
            "Appearance": "Videz",
            "Apply Heat-V protective measures immediately.": "Takoj uvedite zaščitne ukrepe Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Pri UV indeksu 5 ali več se izpostavljenost občutno poveča. Dosledno uporabljajte zaščitna oblačila, pokrivalo za glavo, sončna očala in zaščitno kremo.",
            "Auto": "Samodejno",
            "Call 144 now": "Pokličite 144 zdaj",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Pokličite nujno pomoč (144), če se stanje kmalu ne izboljša ali če so prisotni znaki izgube zavesti",
            "Cancel": "Prekliči",
            "Choose a result": "Izberite rezultat",
            "City, Street...": "Mesto, ulica...",
            "Close": "Zapri",
            "Cool the body, e.g. with damp cloths or ventilation": "Telo hladite z vlažnimi krpami, hladnimi obkladki ali prezračevanjem",
            "Create New Workplace": "Ustvari novo delovno mesto",
            "Critical": "Kritično",
            "Current Risk": "Trenutno tveganje",
            "Dark": "Temno",
            "Data source: GeoSphere Austria": "Vir podatkov: GeoSphere Austria",
            "Delete workplace": "Izbriši delovno mesto",
            "Development": "Razvoj",
            "Elevated": "Povišano",
            "Emergency measures": "Nujni ukrepi",
            "Feels Like": "Občutena temperatura",
            "GeoSphere test URL": "Testni URL GeoSphere",
            "Green": "Zeleno",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Glavobol, vrtoglavica, slabost
            Slabost, krči, zmedenost
            Vroča, suha koža ali zelo potna koža
            Motena zavest
            """,
            "Heat Protection Measures": "Zaščitni ukrepi pred vročino",
            "Heat Safety at a Glance": "Varnost pri vročini na prvi pogled",
            "Heat protection checklist for businesses": "Kontrolni seznam zaščite pred vročino za podjetja",
            "Heat warning level": "Stopnja opozorila pred vročino",
            "Heat warning scale": "Lestvica opozoril pred vročino",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Simptomi, povezani z vročino, lahko vključujejo",
            "High": "Visoko",
            "If set, this URL is used instead of the GeoSphere server.": "Če je nastavljen, se ta URL uporabi namesto strežnika GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Če ni normalnega dihanja, takoj začnite z oživljanjem in pokličite pomoč",
            "If unconscious, place the person in the recovery position": "Če je oseba nezavestna, jo namestite v bočni položaj",
            "Increase breaks and shade usage.": "Povečajte število odmorov in uporabo sence.",
            "Info": "Informacije",
            "Info & Legal": "Informacije in pravno",
            "Label (optional)": "Oznaka (neobvezno)",
            "Later / Skip": "Pozneje / Preskoči",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Osebi dajte piti počasi (voda, čaj, elektrolitske raztopine)",
            "Light": "Svetlo",
            "Live data could not be loaded right now. Please try again later.": "Podatkov v živo trenutno ni bilo mogoče naložiti. Poskusite znova pozneje.",
            "Loading live data": "Nalaganje podatkov v živo",
            "Loosen clothing": "Zrahljajte oblačila",
            "Maximum values across all workplaces": "Najvišje vrednosti na vseh delovnih mestih",
            "Mock active": "Mock aktiven",
            "Mock mode enabled": "Mock način je omogočen",
            "Mock mode stays active until the app is restarted.": "Mock način ostane aktiven do ponovnega zagona aplikacije.",
            "Monitor consciousness and breathing until emergency services arrive": "Spremljajte zavest in dihanje do prihoda nujne pomoči ter ostanite z osebo",
            "Monitored Workplaces": "Nadzorovana delovna mesta",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Kadar je mogoče, prestavite neposredno izpostavljenost soncu in naporno delo v senco ter omejite čas, preživet na močnem soncu.",
            "No active topic subscriptions": "Ni aktivnih naročnin na teme",
            "No matching address found.": "Ni bilo mogoče najti ustreznega naslova.",
            "No workplaces yet.": "Delovnih mest še ni.",
            "Open info": "Odpri informacije",
            "Optional": "Neobvezno",
            "Organizational measures": "Organizacijski ukrepi",
            "Peak UV": "Najvišji UV",
            "Personal protective measures": "Osebni zaščitni ukrepi",
            "Please enter an address.": "Vnesite naslov.",
            "Possible emergency measures": "Možni nujni ukrepi",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Zagotovite dovolj pitne vode
            Lahka delovna oblačila z UV-zaščito in zaščitnim sredstvom za sonce (priporočen SPF 50), UV-zaščitna očala, hladilne brisače
            Glede na področje dela: zaščitna čelada z zaščito za vrat
            """,
            "Quick Glance": "Hiter pregled",
            "Red": "Rdeče",
            "Refresh data": "Osveži podatke",
            "Response plan (STOP principle)": "Načrt ukrepov (načelo STOP)",
            "Search Address": "Išči naslov",
            "Search address or place": "Išči naslov ali kraj",
            "Searching address...": "Iskanje naslova...",
            "Settings": "Nastavitve",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Senčite delovna in počivališča z (mobilnimi) senčniki, paviljoni itd.
            Uporabite tehnične ukrepe hlajenja, kot so ventilatorji
            Zmanjšajte fizično naporno delo, na primer z dvižnimi pripomočki
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Prestavite delovni čas: težka dela načrtujte v hladnejše jutranje ure
            Zagotovite ustrezne odmore za ohlajanje
            Težka opravila izvajajte v senci ali v hladnih območjih
            """,
            "Stable": "Stabilno",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Od stopnje opozorila pred vročino 2 (od 30 °C) je treba uvesti načrt ukrepov in nujne ukrepe. Možni ukrepi vključujejo:",
            "Stay informed": "Ostanite obveščeni",
            "Stop work and move the affected person to shade or a cool place": "Prekinite delo in prizadeto osebo premestite v senco ali v hladen prostor",
            "System": "Sistem",
            "System language": "Jezik sistema",
            "Technical measures": "Tehnični ukrepi",
            "The workplace could not be added.": "Delovnega mesta ni bilo mogoče dodati.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Ta seja aplikacije zdaj prikazuje naključne opozorilne stopnje za vsa delovišča. Način se znova izklopi ob naslednjem zagonu.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "To območje je verjetno zunaj Avstrije ali ga GeoSphere ne prepozna. Dodajanje ni mogoče.",
            "Today": "Danes",
            "Topics": "Teme",
            "Traffic-light status, UV and workplaces live in one view.": "Semaforski status, UV in delovna mesta v živo v enem pogledu.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV indeks >= 5",
            "UV Protection Measures": "Ukrepi UV zaščite",
            "Unable to add": "Ni mogoče dodati",
            "Warnings": "Opozorila",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomagamo vam izpolnjevati zakonske zahteve glede nevarnosti vročine in naravnega UV sevanja pri delu na prostem. Vedno spremljajte temperature in UV indeks.",
            "Welcome to Hitze-V": "Dobrodošli v Hitze-V",
            "Workplaces": "Delovna mesta",
            "Yellow": "Rumeno",
            "n/a": "ni na voljo",
        ],
        .sk: [
            "Push notifications": "Push notifikácie",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Vyberte, či sa majú upozornenia na teplo odosielať ako push notifikácie a pre ktoré pracoviská.",
            "Enable push notifications": "Povoliť push notifikácie",
            "Worksites for push": "Pracoviská pre push notifikácie",
            "Add a worksite first to control push notifications individually.": "Najprv pridajte pracovisko, aby ste mohli push notifikácie spravovať jednotlivo.",
            "No address available": "Adresa nie je k dispozícii",
            "Turning this off immediately removes all current push subscriptions.": "Vypnutím tejto možnosti sa všetky aktuálne push odbery okamžite odstránia.",
            "2 (apparent temperature ≥ 30 °C)": "2 (pocitová teplota ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (pocitová teplota ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (pocitová teplota ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktívne odbery tém",
            "Add": "Pridať",
            "Address search failed. Please try again.": "Vyhľadávanie adresy zlyhalo. Skúste to znova.",
            "Adjust schedules and actively protect teams.": "Upravte rozvrhy a aktívne chráňte tímy.",
            "All clear. Standard precautions are sufficient.": "Všetko je v poriadku. Štandardné opatrenia postačujú.",
            "All day": "Celý deň",
            "Allow & Start": "Povoliť a začať",
            "Appearance": "Vzhľad",
            "Apply Heat-V protective measures immediately.": "Okamžite zaveďte ochranné opatrenia Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Pri UV indexe 5 a vyššom sa expozícia výrazne zvyšuje. Dôsledne používajte ochranný odev, pokrývku hlavy, slnečné okuliare a opaľovací krém.",
            "Auto": "Auto",
            "Call 144 now": "Zavolajte 144 teraz",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Zavolajte záchrannú službu (144), ak sa stav čoskoro nezlepší alebo sú prítomné známky straty vedomia",
            "Cancel": "Zrušiť",
            "Choose a result": "Vyberte výsledok",
            "City, Street...": "Mesto, ulica...",
            "Close": "Zavrieť",
            "Cool the body, e.g. with damp cloths or ventilation": "Ochlaďte telo vlhkými tkaninami, studenými obkladmi alebo vetraním",
            "Create New Workplace": "Vytvoriť nové pracovisko",
            "Critical": "Kritické",
            "Current Risk": "Aktuálne riziko",
            "Dark": "Tmavý",
            "Data source: GeoSphere Austria": "Zdroj údajov: GeoSphere Austria",
            "Delete workplace": "Odstrániť pracovisko",
            "Development": "Vývoj",
            "Elevated": "Zvýšené",
            "Emergency measures": "Núdzové opatrenia",
            "Feels Like": "Pocitová teplota",
            "GeoSphere test URL": "Testovacia URL GeoSphere",
            "Green": "Zelená",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Bolesti hlavy, závraty, nevoľnosť
            Slabosť, kŕče, zmätenosť
            Horúca, suchá pokožka alebo veľmi spotená pokožka
            Porucha vedomia
            """,
            "Heat Protection Measures": "Opatrenia na ochranu pred teplom",
            "Heat Safety at a Glance": "Bezpečnosť pri horúčave na prvý pohľad",
            "Heat protection checklist for businesses": "Kontrolný zoznam ochrany pred teplom pre podniky",
            "Heat warning level": "Stupeň výstrahy pred teplom",
            "Heat warning scale": "Stupnica výstrah pred teplom",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Príznaky súvisiace s teplom môžu zahŕňať",
            "High": "Vysoké",
            "If set, this URL is used instead of the GeoSphere server.": "Ak je nastavená, táto URL sa použije namiesto servera GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Ak nie je prítomné normálne dýchanie, okamžite začnite resuscitáciu a privolajte pomoc",
            "If unconscious, place the person in the recovery position": "Ak je osoba v bezvedomí, uložte ju do stabilizovanej polohy",
            "Increase breaks and shade usage.": "Zvýšte počet prestávok a využívanie tieňa.",
            "Info": "Informácie",
            "Info & Legal": "Informácie a právne",
            "Label (optional)": "Označenie (voliteľné)",
            "Later / Skip": "Neskôr / Preskočiť",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Nechajte osobu piť pomaly (voda, čaj, elektrolytové roztoky)",
            "Light": "Svetlý",
            "Live data could not be loaded right now. Please try again later.": "Živé údaje sa teraz nepodarilo načítať. Skúste to znova neskôr.",
            "Loading live data": "Načítavajú sa živé údaje",
            "Loosen clothing": "Uvoľnite oblečenie",
            "Maximum values across all workplaces": "Maximálne hodnoty na všetkých pracoviskách",
            "Mock active": "Mock aktívny",
            "Mock mode enabled": "Mock režim zapnutý",
            "Mock mode stays active until the app is restarted.": "Mock režim zostáva aktívny až do reštartu aplikácie.",
            "Monitor consciousness and breathing until emergency services arrive": "Sledujte vedomie a dýchanie až do príchodu záchrannej služby a zostaňte pri osobe",
            "Monitored Workplaces": "Sledované pracoviská",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Ak je to možné, presuňte priamu expozíciu slnku a namáhavú prácu do tieňa a obmedzte čas strávený na prudkom slnku.",
            "No active topic subscriptions": "Žiadne aktívne odbery tém",
            "No matching address found.": "Nenašla sa žiadna zodpovedajúca adresa.",
            "No workplaces yet.": "Zatiaľ žiadne pracoviská.",
            "Open info": "Otvoriť informácie",
            "Optional": "Voliteľné",
            "Organizational measures": "Organizačné opatrenia",
            "Peak UV": "Najvyššie UV",
            "Personal protective measures": "Osobné ochranné opatrenia",
            "Please enter an address.": "Zadajte adresu.",
            "Possible emergency measures": "Možné núdzové opatrenia",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Zabezpečte dostatok pitnej vody
            Ľahký pracovný odev s UV ochranou a opaľovacím krémom (odporúča sa SPF 50), okuliare s UV ochranou, chladiace uteráky
            Podľa pracovnej oblasti: ochranná prilba s ochranou krku
            """,
            "Quick Glance": "Rýchly prehľad",
            "Red": "Červená",
            "Refresh data": "Obnoviť údaje",
            "Response plan (STOP principle)": "Plán opatrení (princíp STOP)",
            "Search Address": "Vyhľadať adresu",
            "Search address or place": "Vyhľadať adresu alebo miesto",
            "Searching address...": "Vyhľadáva sa adresa...",
            "Settings": "Nastavenia",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Tiente pracovné a oddychové miesta (mobilnými) slnečníkmi, altánkami atď.
            Používajte technické opatrenia chladenia, ako sú ventilátory
            Znížte fyzicky namáhavú prácu, napríklad pomocou zdvíhacích pomôcok
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Presuňte pracovný čas: ťažkú prácu plánujte na chladnejšie ranné hodiny
            Poskytnite vhodné prestávky na ochladenie
            Ťažké úlohy vykonávajte v tieni alebo v chladných oblastiach
            """,
            "Stable": "Stabilné",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Od stupňa výstrahy pred teplom 2 (od 30 °C) sa musia zaviesť plán opatrení a núdzové opatrenia. Možné opatrenia zahŕňajú:",
            "Stay informed": "Buďte informovaní",
            "Stop work and move the affected person to shade or a cool place": "Prerušte prácu a presuňte postihnutú osobu do tieňa alebo do chladnej miestnosti",
            "System": "Systém",
            "System language": "Jazyk systému",
            "Technical measures": "Technické opatrenia",
            "The workplace could not be added.": "Pracovisko sa nepodarilo pridať.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Táto relácia aplikácie teraz zobrazuje náhodné úrovne výstrahy pre všetky pracoviská. Režim sa pri ďalšom spustení opäť vypne.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Táto oblasť je pravdepodobne mimo Rakúska alebo ju GeoSphere nerozpozná. Pridanie nie je možné.",
            "Today": "Dnes",
            "Topics": "Témy",
            "Traffic-light status, UV and workplaces live in one view.": "Semaforový stav, UV a pracoviská naživo v jednom zobrazení.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV index >= 5",
            "UV Protection Measures": "Opatrenia UV ochrany",
            "Unable to add": "Nedá sa pridať",
            "Warnings": "Upozornenia",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomáhame vám dodržiavať zákonné požiadavky týkajúce sa rizík z tepla a prirodzeného UV žiarenia pri práci vonku. Neustále sledujte teploty a UV index.",
            "Welcome to Hitze-V": "Vitajte v Hitze-V",
            "Workplaces": "Pracoviská",
            "Yellow": "Žltá",
            "n/a": "n/a",
        ],
        .cs: [
            "Push notifications": "Push oznámení",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Vyberte, zda se mají upozornění na horko posílat jako push oznámení a pro která pracoviště.",
            "Enable push notifications": "Povolit push oznámení",
            "Worksites for push": "Pracoviště pro push oznámení",
            "Add a worksite first to control push notifications individually.": "Nejprve přidejte pracoviště, abyste mohli push oznámení spravovat jednotlivě.",
            "No address available": "Adresa není k dispozici",
            "Turning this off immediately removes all current push subscriptions.": "Vypnutím této možnosti se všechny aktuální odběry push okamžitě odstraní.",
            "2 (apparent temperature ≥ 30 °C)": "2 (pocitová teplota ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (pocitová teplota ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (pocitová teplota ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktivní odběry témat",
            "Add": "Přidat",
            "Address search failed. Please try again.": "Vyhledání adresy se nezdařilo. Zkuste to prosím znovu.",
            "Adjust schedules and actively protect teams.": "Upravte rozvrhy a aktivně chraňte týmy.",
            "All clear. Standard precautions are sufficient.": "Vše je v pořádku. Standardní opatření postačují.",
            "All day": "Celý den",
            "Allow & Start": "Povolit a začít",
            "Appearance": "Vzhled",
            "Apply Heat-V protective measures immediately.": "Okamžitě zaveďte ochranná opatření Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Při UV indexu 5 a vyšším se expozice výrazně zvyšuje. Důsledně používejte ochranný oděv, pokrývku hlavy, sluneční brýle a opalovací krém.",
            "Auto": "Auto",
            "Call 144 now": "Zavolejte 144 nyní",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Zavolejte záchrannou službu (144), pokud se stav brzy nezlepší nebo se objeví známky ztráty vědomí",
            "Cancel": "Zrušit",
            "Choose a result": "Vyberte výsledek",
            "City, Street...": "Město, ulice...",
            "Close": "Zavřít",
            "Cool the body, e.g. with damp cloths or ventilation": "Ochlaďte tělo vlhkými látkami, studenými obklady nebo větráním",
            "Create New Workplace": "Vytvořit nové pracoviště",
            "Critical": "Kritické",
            "Current Risk": "Aktuální riziko",
            "Dark": "Tmavý",
            "Data source: GeoSphere Austria": "Zdroj dat: GeoSphere Austria",
            "Delete workplace": "Odstranit pracoviště",
            "Development": "Vývoj",
            "Elevated": "Zvýšené",
            "Emergency measures": "Nouzová opatření",
            "Feels Like": "Pocitová teplota",
            "GeoSphere test URL": "Testovací URL GeoSphere",
            "Green": "Zelená",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Bolest hlavy, závratě, nevolnost
            Slabost, křeče, zmatenost
            Horká, suchá kůže nebo velmi zpocená kůže
            Porucha vědomí
            """,
            "Heat Protection Measures": "Opatření na ochranu před horkem",
            "Heat Safety at a Glance": "Bezpečnost při horku na první pohled",
            "Heat protection checklist for businesses": "Kontrolní seznam ochrany před horkem pro podniky",
            "Heat warning level": "Stupeň varování před horkem",
            "Heat warning scale": "Stupnice varování před horkem",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Příznaky související s horkem mohou zahrnovat",
            "High": "Vysoké",
            "If set, this URL is used instead of the GeoSphere server.": "Pokud je nastavena, použije se tato URL místo serveru GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Pokud není přítomno normální dýchání, okamžitě zahajte resuscitaci a přivolejte pomoc",
            "If unconscious, place the person in the recovery position": "Pokud je osoba v bezvědomí, uložte ji do stabilizované polohy",
            "Increase breaks and shade usage.": "Zvyšte počet přestávek a využívání stínu.",
            "Info": "Informace",
            "Info & Legal": "Informace a právní",
            "Label (optional)": "Označení (volitelné)",
            "Later / Skip": "Později / Přeskočit",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Nechte osobu pomalu pít (vodu, čaj, elektrolytové roztoky)",
            "Light": "Světlý",
            "Live data could not be loaded right now. Please try again later.": "Živá data se nyní nepodařilo načíst. Zkuste to prosím později znovu.",
            "Loading live data": "Načítání živých dat",
            "Loosen clothing": "Uvolněte oděv",
            "Maximum values across all workplaces": "Maximální hodnoty napříč všemi pracovišti",
            "Mock active": "Mock aktivní",
            "Mock mode enabled": "Mock režim zapnutý",
            "Mock mode stays active until the app is restarted.": "Mock režim zůstává aktivní až do restartu aplikace.",
            "Monitor consciousness and breathing until emergency services arrive": "Sledujte vědomí a dýchání až do příjezdu záchranné služby a zůstaňte s osobou",
            "Monitored Workplaces": "Sledovaná pracoviště",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Kdykoli je to možné, přesuňte přímé vystavení slunci a namáhavou práci do stínu a omezte čas strávený na prudkém slunci.",
            "No active topic subscriptions": "Žádné aktivní odběry témat",
            "No matching address found.": "Nebyla nalezena žádná odpovídající adresa.",
            "No workplaces yet.": "Zatím žádná pracoviště.",
            "Open info": "Otevřít informace",
            "Optional": "Volitelné",
            "Organizational measures": "Organizační opatření",
            "Peak UV": "Nejvyšší UV",
            "Personal protective measures": "Osobní ochranná opatření",
            "Please enter an address.": "Zadejte adresu.",
            "Possible emergency measures": "Možná nouzová opatření",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Zajistěte dostatek pitné vody
            Lehký pracovní oděv s UV ochranou a opalovacím krémem (doporučeno SPF 50), brýle s UV ochranou, chladicí ručníky
            Podle oblasti nasazení: ochranná přilba s ochranou krku
            """,
            "Quick Glance": "Rychlý přehled",
            "Red": "Červená",
            "Refresh data": "Obnovit data",
            "Response plan (STOP principle)": "Plán opatření (princip STOP)",
            "Search Address": "Vyhledat adresu",
            "Search address or place": "Vyhledat adresu nebo místo",
            "Searching address...": "Vyhledává se adresa...",
            "Settings": "Nastavení",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Zastiňte pracovní a odpočinková místa (mobilními) slunečníky, pavilony apod.
            Používejte technická chladicí opatření, jako jsou ventilátory
            Snižte fyzicky namáhavou práci, např. použitím zvedacích pomůcek
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Posuňte pracovní dobu: těžkou práci plánujte na chladnější ranní hodiny
            Zajistěte vhodné přestávky na ochlazení
            Těžké úkoly provádějte ve stínu nebo v chladných prostorách
            """,
            "Stable": "Stabilní",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Od stupně varování před horkem 2 (od 30 °C) musí být zavedena opatření a nouzové postupy. Možná opatření zahrnují:",
            "Stay informed": "Zůstaňte informováni",
            "Stop work and move the affected person to shade or a cool place": "Přerušte práci a přemístěte postiženou osobu do stínu nebo do chladné místnosti",
            "System": "Systém",
            "System language": "Jazyk systému",
            "Technical measures": "Technická opatření",
            "The workplace could not be added.": "Pracoviště se nepodařilo přidat.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Tato relace aplikace nyní zobrazuje náhodné stupně varování pro všechna pracoviště. Režim se při dalším spuštění znovu vypne.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Tato oblast je pravděpodobně mimo Rakousko nebo ji GeoSphere nerozpozná. Přidání není možné.",
            "Today": "Dnes",
            "Topics": "Témata",
            "Traffic-light status, UV and workplaces live in one view.": "Semaforový stav, UV a pracoviště živě v jednom zobrazení.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV index >= 5",
            "UV Protection Measures": "Opatření UV ochrany",
            "Unable to add": "Nelze přidat",
            "Warnings": "Varování",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomáháme vám dodržovat zákonné požadavky týkající se rizik z horka a přirozeného UV záření při práci venku. Neustále sledujte teploty a UV index.",
            "Welcome to Hitze-V": "Vítejte v Hitze-V",
            "Workplaces": "Pracoviště",
            "Yellow": "Žlutá",
            "n/a": "n/a",
        ],
        .da: [
            "Push notifications": "Push-notifikationer",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Vælg, om varmeadvarsler skal sendes som push-notifikationer, og for hvilke arbejdspladser.",
            "Enable push notifications": "Aktivér push-notifikationer",
            "Worksites for push": "Arbejdspladser til push",
            "Add a worksite first to control push notifications individually.": "Opret først en arbejdsplads for at styre push-notifikationer individuelt.",
            "No address available": "Ingen adresse tilgængelig",
            "Turning this off immediately removes all current push subscriptions.": "Hvis dette slås fra, fjernes alle nuværende push-abonnementer med det samme.",
            "2 (apparent temperature ≥ 30 °C)": "2 (oplevet temperatur ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (oplevet temperatur ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (oplevet temperatur ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktive emneabonnementer",
            "Add": "Tilføj",
            "Address search failed. Please try again.": "Adressesøgning mislykkedes. Prøv igen.",
            "Adjust schedules and actively protect teams.": "Tilpas tidsplaner og beskyt aktivt teams.",
            "All clear. Standard precautions are sufficient.": "Alt er roligt. Standardforholdsregler er tilstrækkelige.",
            "All day": "Hele dagen",
            "Allow & Start": "Tillad og start",
            "Appearance": "Udseende",
            "Apply Heat-V protective measures immediately.": "Gennemfør straks Heat-V-beskyttelsesforanstaltninger.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Ved UV-indeks 5 og derover stiger eksponeringen markant. Brug konsekvent beskyttelsesbeklædning, hovedbeklædning, solbriller og solcreme.",
            "Auto": "Auto",
            "Call 144 now": "Ring 144 nu",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Ring til alarmtjenesten (144), hvis tilstanden ikke snart forbedres, eller der er tegn på bevidsthedstab",
            "Cancel": "Annuller",
            "Choose a result": "Vælg et resultat",
            "City, Street...": "By, gade...",
            "Close": "Luk",
            "Cool the body, e.g. with damp cloths or ventilation": "Afkøl kroppen med fugtige klude, kolde omslag eller ventilation",
            "Create New Workplace": "Opret ny arbejdsplads",
            "Critical": "Kritisk",
            "Current Risk": "Aktuel risiko",
            "Dark": "Mørk",
            "Data source: GeoSphere Austria": "Datakilde: GeoSphere Austria",
            "Delete workplace": "Slet arbejdsplads",
            "Development": "Udvikling",
            "Elevated": "Forhøjet",
            "Emergency measures": "Akutte tiltag",
            "Feels Like": "Føles som",
            "GeoSphere test URL": "GeoSphere test-URL",
            "Green": "Grøn",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Hovedpine, svimmelhed, kvalme
            Svaghed, kramper, forvirring
            Varm, tør hud eller meget svedig hud
            Påvirket bevidsthed
            """,
            "Heat Protection Measures": "Varmebeskyttelsesforanstaltninger",
            "Heat Safety at a Glance": "Varmesikkerhed i overblik",
            "Heat protection checklist for businesses": "Tjekliste for varmebeskyttelse for virksomheder",
            "Heat warning level": "Varslingsniveau for varme",
            "Heat warning scale": "Skala for varmeadvarsler",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Varmerelevante symptomer kan omfatte",
            "High": "Høj",
            "If set, this URL is used instead of the GeoSphere server.": "Hvis den er angivet, bruges denne URL i stedet for GeoSphere-serveren.",
            "If there is no normal breathing, start CPR immediately and get help": "Hvis der ikke er normal vejrtrækning, skal du straks starte hjertelungeredning og hente hjælp",
            "If unconscious, place the person in the recovery position": "Hvis personen er bevidstløs, læg vedkommende i aflåst sideleje",
            "Increase breaks and shade usage.": "Øg pauser og brugen af skygge.",
            "Info": "Info",
            "Info & Legal": "Info og jura",
            "Label (optional)": "Mærkat (valgfrit)",
            "Later / Skip": "Senere / Spring over",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Lad personen drikke langsomt (vand, te, elektrolytopløsninger)",
            "Light": "Lys",
            "Live data could not be loaded right now. Please try again later.": "Livedata kunne ikke indlæses lige nu. Prøv igen senere.",
            "Loading live data": "Indlæser livedata",
            "Loosen clothing": "Løsn tøjet",
            "Maximum values across all workplaces": "Maksimale værdier på tværs af alle arbejdspladser",
            "Mock active": "Mock aktiv",
            "Mock mode enabled": "Mock-tilstand aktiveret",
            "Mock mode stays active until the app is restarted.": "Mock-tilstand forbliver aktiv, indtil appen genstartes.",
            "Monitor consciousness and breathing until emergency services arrive": "Overvåg bevidsthed og vejrtrækning, indtil redningstjenesten kommer, og bliv hos personen",
            "Monitored Workplaces": "Overvågede arbejdspladser",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Flyt direkte soleksponering og anstrengende arbejde i skyggen, når det er muligt, og begræns tiden i fuld sol.",
            "No active topic subscriptions": "Ingen aktive emneabonnementer",
            "No matching address found.": "Ingen matchende adresse fundet.",
            "No workplaces yet.": "Ingen arbejdspladser endnu.",
            "Open info": "Åbn info",
            "Optional": "Valgfri",
            "Organizational measures": "Organisatoriske foranstaltninger",
            "Peak UV": "Højeste UV",
            "Personal protective measures": "Personlige beskyttelsesforanstaltninger",
            "Please enter an address.": "Indtast en adresse.",
            "Possible emergency measures": "Mulige akutforanstaltninger",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Sørg for tilstrækkeligt drikkevand
            Let arbejdstøj med UV-beskyttelse og solcreme (SPF 50 anbefales), UV-beskyttelsesbriller, kølehåndklæder
            Afhængigt af arbejdsområdet: beskyttelseshjelm med nakkebeskyttelse
            """,
            "Quick Glance": "Hurtigt overblik",
            "Red": "Rød",
            "Refresh data": "Opdater data",
            "Response plan (STOP principle)": "Handleplan (STOP-princippet)",
            "Search Address": "Søg adresse",
            "Search address or place": "Søg adresse eller sted",
            "Searching address...": "Søger adresse...",
            "Settings": "Indstillinger",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Skyg arbejds- og hvileområder med (mobile) parasoller, pavilloner osv.
            Brug tekniske køleforanstaltninger såsom ventilatorer
            Reducer fysisk anstrengende arbejde, f.eks. ved brug af løftehjælpemidler
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Flyt arbejdstiden: planlæg tungt arbejde til køligere morgentimer
            Sørg for passende pauser til nedkøling
            Udfør tunge opgaver i skygge eller kølige områder
            """,
            "Stable": "Stabil",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Fra varslingsniveau 2 for varme (fra 30 °C) skal der gennemføres en handleplan og akutte tiltag. Mulige tiltag omfatter:",
            "Stay informed": "Hold dig informeret",
            "Stop work and move the affected person to shade or a cool place": "Stop arbejdet og flyt den berørte person til skygge eller et køligt rum",
            "System": "System",
            "System language": "Systemsprog",
            "Technical measures": "Tekniske foranstaltninger",
            "The workplace could not be added.": "Arbejdspladsen kunne ikke tilføjes.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Denne app-session viser nu tilfældige advarselsniveauer for alle arbejdssteder. Tilstanden slås fra igen ved næste genstart.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Dette område ligger sandsynligvis uden for Østrig eller genkendes ikke af GeoSphere. Tilføjelse er ikke mulig.",
            "Today": "I dag",
            "Topics": "Emner",
            "Traffic-light status, UV and workplaces live in one view.": "Trafiklysstatus, UV og arbejdspladser live i én visning.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-indeks >= 5",
            "UV Protection Measures": "UV-beskyttelsesforanstaltninger",
            "Unable to add": "Kan ikke tilføje",
            "Warnings": "Advarsler",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Vi hjælper dig med at overholde lovkrav om farer fra varme og naturlig UV-stråling ved udendørs arbejde. Hold altid øje med temperaturer og UV-indeks.",
            "Welcome to Hitze-V": "Velkommen til Hitze-V",
            "Workplaces": "Arbejdspladser",
            "Yellow": "Gul",
            "n/a": "ikke tilg.",
        ],
        .fi: [
            "Push notifications": "Push-ilmoitukset",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Valitse, lähetetäänkö kuumuusvaroitukset push-ilmoituksina ja mille työpaikoille.",
            "Enable push notifications": "Ota push-ilmoitukset käyttöön",
            "Worksites for push": "Työpaikat push-ilmoituksille",
            "Add a worksite first to control push notifications individually.": "Lisää ensin työpaikka, jotta voit hallita push-ilmoituksia erikseen.",
            "No address available": "Osoitetta ei ole saatavilla",
            "Turning this off immediately removes all current push subscriptions.": "Tämän poistaminen käytöstä poistaa heti kaikki nykyiset push-tilaukset.",
            "2 (apparent temperature ≥ 30 °C)": "2 (tuntuva lämpötila ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (tuntuva lämpötila ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (tuntuva lämpötila ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktiiviset aihetilaukset",
            "Add": "Lisää",
            "Address search failed. Please try again.": "Osoitteen haku epäonnistui. Yritä uudelleen.",
            "Adjust schedules and actively protect teams.": "Mukauta aikatauluja ja suojaa tiimejä aktiivisesti.",
            "All clear. Standard precautions are sufficient.": "Kaikki kunnossa. Tavanomaiset varotoimet riittävät.",
            "All day": "Koko päivä",
            "Allow & Start": "Salli ja aloita",
            "Appearance": "Ulkoasu",
            "Apply Heat-V protective measures immediately.": "Ota Heat-V-suojatoimet käyttöön välittömästi.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "UV-indeksin ollessa 5 tai enemmän altistus kasvaa merkittävästi. Käytä johdonmukaisesti suojavaatetusta, päähinettä, aurinkolaseja ja aurinkovoidetta.",
            "Auto": "Auto",
            "Call 144 now": "Soita 144 nyt",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Soita hätänumeroon (144), jos tila ei pian parane tai on merkkejä tajunnan menetyksestä",
            "Cancel": "Peruuta",
            "Choose a result": "Valitse tulos",
            "City, Street...": "Kaupunki, katu...",
            "Close": "Sulje",
            "Cool the body, e.g. with damp cloths or ventilation": "Viilennä kehoa kosteilla liinoilla, kylmillä kääreillä tai tuuletuksella",
            "Create New Workplace": "Luo uusi työpaikka",
            "Critical": "Kriittinen",
            "Current Risk": "Nykyinen riski",
            "Dark": "Tumma",
            "Data source: GeoSphere Austria": "Tietolähde: GeoSphere Austria",
            "Delete workplace": "Poista työpaikka",
            "Development": "Kehitys",
            "Elevated": "Kohonnut",
            "Emergency measures": "Hätätoimenpiteet",
            "Feels Like": "Tuntuu kuin",
            "GeoSphere test URL": "GeoSphere-testi-URL",
            "Green": "Vihreä",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Päänsärky, huimaus, pahoinvointi
            Heikkous, kouristukset, sekavuus
            Kuuma, kuiva iho tai hyvin hikinen iho
            Tajunnan heikentyminen
            """,
            "Heat Protection Measures": "Lämpösuojelutoimet",
            "Heat Safety at a Glance": "Turvallisuus kuumuudessa yhdellä silmäyksellä",
            "Heat protection checklist for businesses": "Kuumuudensuojauksen tarkistuslista yrityksille",
            "Heat warning level": "Lämpövaroituksen taso",
            "Heat warning scale": "Lämpövaroitusasteikko",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Kuumuuteen liittyviä oireita voivat olla",
            "High": "Korkea",
            "If set, this URL is used instead of the GeoSphere server.": "Jos tämä on asetettu, tätä URL-osoitetta käytetään GeoSphere-palvelimen sijasta.",
            "If there is no normal breathing, start CPR immediately and get help": "Jos normaalia hengitystä ei ole, aloita elvytys heti ja hälytä apua",
            "If unconscious, place the person in the recovery position": "Jos henkilö on tajuton, aseta hänet kylkiasentoon",
            "Increase breaks and shade usage.": "Lisää taukoja ja varjon käyttöä.",
            "Info": "Info",
            "Info & Legal": "Info ja lakiasiat",
            "Label (optional)": "Nimiö (valinnainen)",
            "Later / Skip": "Myöhemmin / Ohita",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Anna henkilön juoda hitaasti (vettä, teetä, elektrolyyttiliuoksia)",
            "Light": "Vaalea",
            "Live data could not be loaded right now. Please try again later.": "Live-dataa ei voitu ladata juuri nyt. Yritä myöhemmin uudelleen.",
            "Loading live data": "Ladataan live-dataa",
            "Loosen clothing": "Löysää vaatteita",
            "Maximum values across all workplaces": "Enimmäisarvot kaikissa työpaikoissa",
            "Mock active": "Mock aktiivinen",
            "Mock mode enabled": "Mock-tila käytössä",
            "Mock mode stays active until the app is restarted.": "Mock-tila pysyy aktiivisena, kunnes sovellus käynnistetään uudelleen.",
            "Monitor consciousness and breathing until emergency services arrive": "Seuraa tajuntaa ja hengitystä, kunnes ensihoito saapuu, ja pysy henkilön luona",
            "Monitored Workplaces": "Seuratut työpaikat",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Siirrä suora auringolle altistuminen ja raskas työ varjoon aina kun mahdollista ja rajoita aikaa paahteisessa auringossa.",
            "No active topic subscriptions": "Ei aktiivisia aihetilauksia",
            "No matching address found.": "Yhtään vastaavaa osoitetta ei löytynyt.",
            "No workplaces yet.": "Työpaikkoja ei vielä ole.",
            "Open info": "Avaa info",
            "Optional": "Valinnainen",
            "Organizational measures": "Organisatoriset toimet",
            "Peak UV": "Korkein UV",
            "Personal protective measures": "Henkilökohtaiset suojatoimet",
            "Please enter an address.": "Anna osoite.",
            "Possible emergency measures": "Mahdolliset hätätoimenpiteet",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Tarjoa riittävästi juomavettä
            Kevyt työvaatetus, jossa on UV-suoja, sekä aurinkovoide (SPF 50 suositellaan), UV-suojalasit, viilennysliinat
            Työalueesta riippuen: suojakypärä niskasuojaimella
            """,
            "Quick Glance": "Pikakatsaus",
            "Red": "Punainen",
            "Refresh data": "Päivitä tiedot",
            "Response plan (STOP principle)": "Toimintasuunnitelma (STOP-periaate)",
            "Search Address": "Hae osoite",
            "Search address or place": "Hae osoitetta tai paikkaa",
            "Searching address...": "Haetaan osoitetta...",
            "Settings": "Asetukset",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Varjosta työ- ja lepoalueet (siirrettävillä) aurinkovarjoilla, paviljongeilla jne.
            Käytä teknisiä viilennystoimia, kuten tuulettimia
            Vähennä fyysisesti raskasta työtä esimerkiksi nostovälineillä
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Siirrä työaikoja: ajoita raskaat työt viileämpiin aamutunteihin
            Järjestä sopivat tauot viilentymistä varten
            Suorita raskaat tehtävät varjossa tai viileissä tiloissa
            """,
            "Stable": "Vakaa",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Lämpövaroitustasosta 2 alkaen (30 °C:sta lähtien) on toteutettava toimintasuunnitelma ja hätätoimenpiteet. Mahdollisia toimenpiteitä ovat muun muassa:",
            "Stay informed": "Pysy ajan tasalla",
            "Stop work and move the affected person to shade or a cool place": "Keskeytä työ ja siirrä altistunut henkilö varjoon tai viileään tilaan",
            "System": "Järjestelmä",
            "System language": "Järjestelmän kieli",
            "Technical measures": "Tekniset toimet",
            "The workplace could not be added.": "Työpaikkaa ei voitu lisätä.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Tämä sovellusistunto näyttää nyt satunnaisia varoitustasoja kaikille työpaikoille. Tila poistuu käytöstä seuraavan uudelleenkäynnistyksen yhteydessä.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Tämä alue on todennäköisesti Itävallan ulkopuolella tai GeoSphere ei tunnista sitä. Lisääminen ei ole mahdollista.",
            "Today": "Tänään",
            "Topics": "Aiheet",
            "Traffic-light status, UV and workplaces live in one view.": "Liikennevalotila, UV ja työpaikat yhdessä live-näkymässä.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-indeksi >= 5",
            "UV Protection Measures": "UV-suojatoimet",
            "Unable to add": "Ei voida lisätä",
            "Warnings": "Varoitukset",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Autamme sinua noudattamaan lakisääteisiä vaatimuksia, jotka koskevat kuumuuden ja luonnollisen UV-säteilyn riskejä ulkotyössä. Seuraa lämpötiloja ja UV-indeksiä jatkuvasti.",
            "Welcome to Hitze-V": "Tervetuloa Hitze-V:hen",
            "Workplaces": "Työpaikat",
            "Yellow": "Keltainen",
            "n/a": "ei saat.",
        ],
        .et: [
            "Push notifications": "Push-teavitused",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Vali, kas kuumahoiatused saadetakse push-teavitustena ja milliste töökohtade jaoks.",
            "Enable push notifications": "Luba push-teavitused",
            "Worksites for push": "Töökohad push-teavitustele",
            "Add a worksite first to control push notifications individually.": "Lisa esmalt töökoht, et saaksid push-teavitusi eraldi hallata.",
            "No address available": "Aadress puudub",
            "Turning this off immediately removes all current push subscriptions.": "Selle väljalülitamine eemaldab kohe kõik praegused push-tellimused.",
            "2 (apparent temperature ≥ 30 °C)": "2 (tajutav temperatuur ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (tajutav temperatuur ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (tajutav temperatuur ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktiivsed teematellimused",
            "Add": "Lisa",
            "Address search failed. Please try again.": "Aadressi otsing ebaõnnestus. Proovi uuesti.",
            "Adjust schedules and actively protect teams.": "Kohanda ajakavasid ja kaitse meeskondi aktiivselt.",
            "All clear. Standard precautions are sufficient.": "Kõik on korras. Tavalised ettevaatusabinõud on piisavad.",
            "All day": "Kogu päev",
            "Allow & Start": "Luba ja alusta",
            "Appearance": "Välimus",
            "Apply Heat-V protective measures immediately.": "Rakenda Heat-V kaitsemeetmed kohe.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "UV-indeksi 5 ja enam korral suureneb kokkupuude märgatavalt. Kasuta järjepidevalt kaitseriietust, peakatet, päikeseprille ja päikesekreemi.",
            "Auto": "Automaatne",
            "Call 144 now": "Helista kohe 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Helista hädaabisse (144), kui seisund peagi ei parane või ilmnevad teadvusekao tunnused",
            "Cancel": "Tühista",
            "Choose a result": "Vali tulemus",
            "City, Street...": "Linn, tänav...",
            "Close": "Sulge",
            "Cool the body, e.g. with damp cloths or ventilation": "Jahuta keha niiskete lappide, külmade kompresside või tuulutusega",
            "Create New Workplace": "Loo uus töökoht",
            "Critical": "Kriitiline",
            "Current Risk": "Praegune risk",
            "Dark": "Tume",
            "Data source: GeoSphere Austria": "Andmeallikas: GeoSphere Austria",
            "Delete workplace": "Kustuta töökoht",
            "Development": "Arendus",
            "Elevated": "Kõrgenenud",
            "Emergency measures": "Esmaabimeetmed",
            "Feels Like": "Tundub nagu",
            "GeoSphere test URL": "GeoSphere test-URL",
            "Green": "Roheline",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Peavalu, pearinglus, iiveldus
            Nõrkus, krambid, segasus
            Kuum, kuiv nahk või väga higine nahk
            Häiritud teadvus
            """,
            "Heat Protection Measures": "Kuumakaitsemeetmed",
            "Heat Safety at a Glance": "Kuumaturvalisus lühidalt",
            "Heat protection checklist for businesses": "Kuumakaitse kontrollnimekiri ettevõtetele",
            "Heat warning level": "Kuumahoiatuse tase",
            "Heat warning scale": "Kuumahoiatuse skaala",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Kuumusega seotud sümptomid võivad hõlmata",
            "High": "Kõrge",
            "If set, this URL is used instead of the GeoSphere server.": "Kui see on määratud, kasutatakse seda URL-i GeoSphere serveri asemel.",
            "If there is no normal breathing, start CPR immediately and get help": "Kui normaalne hingamine puudub, alusta kohe elustamist ja kutsu abi",
            "If unconscious, place the person in the recovery position": "Kui inimene on teadvuseta, aseta ta stabiilsesse küliliasendisse",
            "Increase breaks and shade usage.": "Suurenda pause ja varju kasutamist.",
            "Info": "Info",
            "Info & Legal": "Info ja juriidiline teave",
            "Label (optional)": "Silt (valikuline)",
            "Later / Skip": "Hiljem / Jäta vahele",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Lase inimesel aeglaselt juua (vett, teed, elektrolüüdilahuseid)",
            "Light": "Hele",
            "Live data could not be loaded right now. Please try again later.": "Reaalaja andmeid ei saanud praegu laadida. Proovi hiljem uuesti.",
            "Loading live data": "Reaalaja andmete laadimine",
            "Loosen clothing": "Lõdvenda riideid",
            "Maximum values across all workplaces": "Maksimaalsed väärtused kõigi töökohtade lõikes",
            "Mock active": "Mock aktiivne",
            "Mock mode enabled": "Mock-režiim on sisse lülitatud",
            "Mock mode stays active until the app is restarted.": "Mock-režiim püsib aktiivne kuni rakenduse taaskäivitamiseni.",
            "Monitor consciousness and breathing until emergency services arrive": "Jälgi teadvust ja hingamist kuni abi saabumiseni ning jää inimese juurde",
            "Monitored Workplaces": "Jälgitavad töökohad",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Vii otsene päikese käes viibimine ja raske töö võimaluse korral varju ning piira täispäikese käes veedetud aega.",
            "No active topic subscriptions": "Aktiivseid teematellimusi pole",
            "No matching address found.": "Sobivat aadressi ei leitud.",
            "No workplaces yet.": "Töökohti veel pole.",
            "Open info": "Ava info",
            "Optional": "Valikuline",
            "Organizational measures": "Korralduslikud meetmed",
            "Peak UV": "Kõrgeim UV",
            "Personal protective measures": "Isiklikud kaitsemeetmed",
            "Please enter an address.": "Sisesta aadress.",
            "Possible emergency measures": "Võimalikud esmaabimeetmed",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Tagage piisavalt joogivett
            Kerged UV-kaitsega tööriided ja päikesekaitsevahend (soovitatav SPF 50), UV-kaitseprillid, jahutavad rätikud
            Olenevalt töövaldkonnast: kaitsekiiver kaelakaitsega
            """,
            "Quick Glance": "Kiirülevaade",
            "Red": "Punane",
            "Refresh data": "Värskenda andmeid",
            "Response plan (STOP principle)": "Tegevusplaan (STOP-põhimõte)",
            "Search Address": "Otsi aadressi",
            "Search address or place": "Otsi aadressi või kohta",
            "Searching address...": "Aadressi otsimine...",
            "Settings": "Seaded",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Varjuta töö- ja puhkealad (mobiilsete) päikesevarjude, paviljonide jne abil
            Kasuta tehnilisi jahutusmeetmeid, näiteks ventilaatoreid
            Vähenda füüsiliselt rasket tööd, näiteks tõsteabivahendite abil
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Nihuta tööaegu: planeeri raske töö jahedamatele hommikutundidele
            Paku sobivaid jahutuspause
            Tee rasked ülesanded varjus või jahedates piirkondades
            """,
            "Stable": "Stabiilne",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Alates kuumahoiatuse tasemest 2 (alates 30 °C) tuleb rakendada tegevusplaan ja erakorralised meetmed. Võimalikud meetmed on näiteks:",
            "Stay informed": "Püsi kursis",
            "Stop work and move the affected person to shade or a cool place": "Peata töö ja vii kannatanu varju või jahedasse ruumi",
            "System": "Süsteem",
            "System language": "Süsteemi keel",
            "Technical measures": "Tehnilised meetmed",
            "The workplace could not be added.": "Töökohta ei saanud lisada.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "See rakenduse seanss kuvab nüüd kõigi töökohtade jaoks juhuslikke hoiatusastmeid. Režiim lülitub järgmisel taaskäivitamisel välja.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "See piirkond asub tõenäoliselt väljaspool Austriat või GeoSphere ei tunne seda ära. Lisamine ei ole võimalik.",
            "Today": "Täna",
            "Topics": "Teemad",
            "Traffic-light status, UV and workplaces live in one view.": "Foori olek, UV ja töökohad ühes reaalajas vaates.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-indeks >= 5",
            "UV Protection Measures": "UV-kaitsemeetmed",
            "Unable to add": "Ei saa lisada",
            "Warnings": "Hoiatused",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Aitame sul täita õigusnõudeid, mis puudutavad kuumuse ja loodusliku UV-kiirguse ohte välitöödel. Hoia temperatuuridel ja UV-indeksil alati silm peal.",
            "Welcome to Hitze-V": "Tere tulemast Hitze-V-sse",
            "Workplaces": "Töökohad",
            "Yellow": "Kollane",
            "n/a": "pole saadaval",
        ],
        .lv: [
            "Push notifications": "Push paziņojumi",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Izvēlieties, vai karstuma brīdinājumi jānosūta kā push paziņojumi un kurām darba vietām.",
            "Enable push notifications": "Ieslēgt push paziņojumus",
            "Worksites for push": "Darba vietas push paziņojumiem",
            "Add a worksite first to control push notifications individually.": "Vispirms pievienojiet darba vietu, lai varētu atsevišķi pārvaldīt push paziņojumus.",
            "No address available": "Adrese nav pieejama",
            "Turning this off immediately removes all current push subscriptions.": "Izslēdzot šo opciju, visas pašreizējās push abonēšanas tiek nekavējoties noņemtas.",
            "2 (apparent temperature ≥ 30 °C)": "2 (sajūtamā temperatūra ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (sajūtamā temperatūra ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (sajūtamā temperatūra ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktīvie tēmu abonementi",
            "Add": "Pievienot",
            "Address search failed. Please try again.": "Adreses meklēšana neizdevās. Mēģiniet vēlreiz.",
            "Adjust schedules and actively protect teams.": "Pielāgojiet grafikus un aktīvi aizsargājiet komandas.",
            "All clear. Standard precautions are sufficient.": "Viss kārtībā. Standarta piesardzības pasākumi ir pietiekami.",
            "All day": "Visu dienu",
            "Allow & Start": "Atļaut un sākt",
            "Appearance": "Izskats",
            "Apply Heat-V protective measures immediately.": "Nekavējoties īstenojiet Heat-V aizsardzības pasākumus.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Pie UV indeksa 5 un augstāka iedarbība ievērojami palielinās. Pastāvīgi lietojiet aizsargapģērbu, galvassegu, saulesbrilles un saules aizsargkrēmu.",
            "Auto": "Auto",
            "Call 144 now": "Zvaniet uz 144 tagad",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Zvaniet neatliekamajai palīdzībai (144), ja stāvoklis drīz neuzlabojas vai ir apziņas zuduma pazīmes",
            "Cancel": "Atcelt",
            "Choose a result": "Izvēlieties rezultātu",
            "City, Street...": "Pilsēta, iela...",
            "Close": "Aizvērt",
            "Cool the body, e.g. with damp cloths or ventilation": "Atvēsiniet ķermeni ar mitrām drānām, aukstām kompresēm vai ventilāciju",
            "Create New Workplace": "Izveidot jaunu darba vietu",
            "Critical": "Kritisks",
            "Current Risk": "Pašreizējais risks",
            "Dark": "Tumšs",
            "Data source: GeoSphere Austria": "Datu avots: GeoSphere Austria",
            "Delete workplace": "Dzēst darba vietu",
            "Development": "Izstrāde",
            "Elevated": "Paaugstināts",
            "Emergency measures": "Neatliekamie pasākumi",
            "Feels Like": "Sajūtamā temperatūra",
            "GeoSphere test URL": "GeoSphere testa URL",
            "Green": "Zaļš",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Galvassāpes, reibonis, slikta dūša
            Vājums, krampji, apjukums
            Karsta, sausa āda vai ļoti sviedraina āda
            Apziņas traucējumi
            """,
            "Heat Protection Measures": "Aizsardzības pasākumi pret karstumu",
            "Heat Safety at a Glance": "Drošība karstumā vienā skatā",
            "Heat protection checklist for businesses": "Kontrolsaraksts aizsardzībai pret karstumu uzņēmumiem",
            "Heat warning level": "Karstuma brīdinājuma līmenis",
            "Heat warning scale": "Karstuma brīdinājuma skala",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Ar karstumu saistītie simptomi var ietvert",
            "High": "Augsts",
            "If set, this URL is used instead of the GeoSphere server.": "Ja iestatīts, šis URL tiek izmantots GeoSphere servera vietā.",
            "If there is no normal breathing, start CPR immediately and get help": "Ja nav normālas elpošanas, nekavējoties sāciet atdzīvināšanu un sauciet palīdzību",
            "If unconscious, place the person in the recovery position": "Ja persona ir bezsamaņā, novietojiet to stabilā sānu pozā",
            "Increase breaks and shade usage.": "Palieliniet pārtraukumu skaitu un ēnas izmantošanu.",
            "Info": "Informācija",
            "Info & Legal": "Informācija un juridiskā informācija",
            "Label (optional)": "Etiķete (neobligāti)",
            "Later / Skip": "Vēlāk / Izlaist",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Ļaujiet personai dzert lēnām (ūdeni, tēju, elektrolītu šķīdumus)",
            "Light": "Gaišs",
            "Live data could not be loaded right now. Please try again later.": "Tiešraides datus pašlaik nevarēja ielādēt. Mēģiniet vēlreiz vēlāk.",
            "Loading live data": "Tiešraides datu ielāde",
            "Loosen clothing": "Atbrīvojiet apģērbu",
            "Maximum values across all workplaces": "Maksimālās vērtības visās darba vietās",
            "Mock active": "Mock aktīvs",
            "Mock mode enabled": "Mock režīms ieslēgts",
            "Mock mode stays active until the app is restarted.": "Mock režīms paliek aktīvs līdz lietotnes restartēšanai.",
            "Monitor consciousness and breathing until emergency services arrive": "Uzraugiet apziņu un elpošanu līdz neatliekamās palīdzības ierašanās brīdim un palieciet kopā ar personu",
            "Monitored Workplaces": "Uzraudzītās darba vietas",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Kad vien iespējams, pārvietojiet tiešu saules iedarbību un smagu darbu ēnā un ierobežojiet laiku pilnā saulē.",
            "No active topic subscriptions": "Nav aktīvu tēmu abonementu",
            "No matching address found.": "Netika atrasta atbilstoša adrese.",
            "No workplaces yet.": "Vēl nav nevienas darba vietas.",
            "Open info": "Atvērt informāciju",
            "Optional": "Neobligāti",
            "Organizational measures": "Organizatoriskie pasākumi",
            "Peak UV": "Maksimālais UV",
            "Personal protective measures": "Personīgie aizsardzības pasākumi",
            "Please enter an address.": "Ievadiet adresi.",
            "Possible emergency measures": "Iespējamie neatliekamie pasākumi",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Nodrošiniet pietiekami daudz dzeramā ūdens
            Viegls darba apģērbs ar UV aizsardzību un saules aizsarglīdzekli (ieteicams SPF 50), UV aizsargbrilles, dzesējoši dvieļi
            Atkarībā no darba jomas: aizsargķivere ar kakla aizsardzību
            """,
            "Quick Glance": "Ātrais pārskats",
            "Red": "Sarkans",
            "Refresh data": "Atsvaidzināt datus",
            "Response plan (STOP principle)": "Rīcības plāns (STOP princips)",
            "Search Address": "Meklēt adresi",
            "Search address or place": "Meklēt adresi vai vietu",
            "Searching address...": "Notiek adreses meklēšana...",
            "Settings": "Iestatījumi",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Ēnojiet darba un atpūtas zonas ar (pārvietojamiem) saulessargiem, paviljoniem utt.
            Izmantojiet tehniskus dzesēšanas pasākumus, piemēram, ventilatorus
            Samaziniet fiziski smagu darbu, piemēram, izmantojot celšanas palīglīdzekļus
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Mainiet darba laiku: smago darbu plānojiet vēsākajās rīta stundās
            Nodrošiniet piemērotus pārtraukumus atvēsināšanai
            Veiciet smagos darbus ēnā vai vēsās vietās
            """,
            "Stable": "Stabils",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Sākot ar karstuma brīdinājuma 2. līmeni (no 30 °C), ir jāievieš rīcības plāns un neatliekamie pasākumi. Iespējamie pasākumi ietver:",
            "Stay informed": "Esiet informēti",
            "Stop work and move the affected person to shade or a cool place": "Pārtrauciet darbu un pārvietojiet cietušo ēnā vai vēsā telpā",
            "System": "Sistēma",
            "System language": "Sistēmas valoda",
            "Technical measures": "Tehniskie pasākumi",
            "The workplace could not be added.": "Darba vietu neizdevās pievienot.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Šī lietotnes sesija tagad rāda nejaušus brīdinājuma līmeņus visām darba vietām. Režīms atkal izslēgsies nākamajā restartēšanā.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Šī teritorija, visticamāk, atrodas ārpus Austrijas vai GeoSphere to neatpazīst. Pievienošana nav iespējama.",
            "Today": "Šodien",
            "Topics": "Tēmas",
            "Traffic-light status, UV and workplaces live in one view.": "Luksofora statuss, UV un darba vietas tiešraidē vienā skatā.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV indekss >= 5",
            "UV Protection Measures": "UV aizsardzības pasākumi",
            "Unable to add": "Nevar pievienot",
            "Warnings": "Brīdinājumi",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Mēs palīdzam ievērot juridiskās prasības attiecībā uz karstuma un dabiskā UV starojuma riskiem āra darbā. Vienmēr sekojiet temperatūrai un UV indeksam.",
            "Welcome to Hitze-V": "Laipni lūdzam Hitze-V",
            "Workplaces": "Darba vietas",
            "Yellow": "Dzeltens",
            "n/a": "nav pieejams",
        ],
        .lt: [
            "Push notifications": "Push pranešimai",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Pasirinkite, ar karščio įspėjimai turi būti siunčiami kaip push pranešimai ir kurioms darbo vietoms.",
            "Enable push notifications": "Įjungti push pranešimus",
            "Worksites for push": "Darbo vietos push pranešimams",
            "Add a worksite first to control push notifications individually.": "Pirmiausia pridėkite darbo vietą, kad galėtumėte atskirai valdyti push pranešimus.",
            "No address available": "Adresas nepasiekiamas",
            "Turning this off immediately removes all current push subscriptions.": "Išjungus šią parinktį, visi dabartiniai push prenumeratos bus nedelsiant pašalinti.",
            "2 (apparent temperature ≥ 30 °C)": "2 (jutiminė temperatūra ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (jutiminė temperatūra ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (jutiminė temperatūra ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktyvios temų prenumeratos",
            "Add": "Pridėti",
            "Address search failed. Please try again.": "Adreso paieška nepavyko. Bandykite dar kartą.",
            "Adjust schedules and actively protect teams.": "Pritaikykite grafikus ir aktyviai saugokite komandas.",
            "All clear. Standard precautions are sufficient.": "Viskas ramu. Pakanka standartinių atsargumo priemonių.",
            "All day": "Visą dieną",
            "Allow & Start": "Leisti ir pradėti",
            "Appearance": "Išvaizda",
            "Apply Heat-V protective measures immediately.": "Nedelsdami taikykite Heat-V apsaugos priemones.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Esant 5 ir didesniam UV indeksui poveikis gerokai padidėja. Nuosekliai naudokite apsauginius drabužius, galvos apdangalą, saulės akinius ir kremą nuo saulės.",
            "Auto": "Automatiškai",
            "Call 144 now": "Skambinkite 144 dabar",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Skambinkite skubios pagalbos tarnyboms (144), jei būklė netrukus nepagerėja arba yra sąmonės netekimo požymių",
            "Cancel": "Atšaukti",
            "Choose a result": "Pasirinkite rezultatą",
            "City, Street...": "Miestas, gatvė...",
            "Close": "Uždaryti",
            "Cool the body, e.g. with damp cloths or ventilation": "Vėsinkite kūną drėgnomis šluostėmis, šaltais kompresais arba ventiliacija",
            "Create New Workplace": "Sukurti naują darbo vietą",
            "Critical": "Kritinis",
            "Current Risk": "Dabartinė rizika",
            "Dark": "Tamsi",
            "Data source: GeoSphere Austria": "Duomenų šaltinis: GeoSphere Austria",
            "Delete workplace": "Ištrinti darbo vietą",
            "Development": "Kūrimas",
            "Elevated": "Padidėjęs",
            "Emergency measures": "Skubios priemonės",
            "Feels Like": "Jaučiama kaip",
            "GeoSphere test URL": "GeoSphere bandomasis URL",
            "Green": "Žalia",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Galvos skausmas, galvos svaigimas, pykinimas
            Silpnumas, mėšlungis, sumišimas
            Karšta, sausa oda arba labai prakaituojanti oda
            Sąmonės sutrikimas
            """,
            "Heat Protection Measures": "Apsaugos nuo karščio priemonės",
            "Heat Safety at a Glance": "Sauga karštyje vienu žvilgsniu",
            "Heat protection checklist for businesses": "Apsaugos nuo karščio kontrolinis sąrašas įmonėms",
            "Heat warning level": "Karščio perspėjimo lygis",
            "Heat warning scale": "Karščio perspėjimo skalė",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Su karščiu susiję simptomai gali apimti",
            "High": "Aukštas",
            "If set, this URL is used instead of the GeoSphere server.": "Jei nustatyta, vietoje GeoSphere serverio bus naudojamas šis URL.",
            "If there is no normal breathing, start CPR immediately and get help": "Jei nėra normalaus kvėpavimo, nedelsdami pradėkite gaivinimą ir kvieskite pagalbą",
            "If unconscious, place the person in the recovery position": "Jei žmogus be sąmonės, paguldykite jį į stabilią šoninę padėtį",
            "Increase breaks and shade usage.": "Padidinkite pertraukų skaičių ir šešėlio naudojimą.",
            "Info": "Informacija",
            "Info & Legal": "Informacija ir teisinė informacija",
            "Label (optional)": "Žyma (nebūtina)",
            "Later / Skip": "Vėliau / Praleisti",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Leiskite žmogui gerti lėtai (vandenį, arbatą, elektrolitų tirpalus)",
            "Light": "Šviesi",
            "Live data could not be loaded right now. Please try again later.": "Tiesioginių duomenų dabar nepavyko įkelti. Bandykite dar kartą vėliau.",
            "Loading live data": "Įkeliami tiesioginiai duomenys",
            "Loosen clothing": "Atlaisvinkite drabužius",
            "Maximum values across all workplaces": "Didžiausios vertės visose darbo vietose",
            "Mock active": "Mock aktyvus",
            "Mock mode enabled": "Mock režimas įjungtas",
            "Mock mode stays active until the app is restarted.": "Mock režimas išlieka aktyvus iki programėlės paleidimo iš naujo.",
            "Monitor consciousness and breathing until emergency services arrive": "Stebėkite sąmonę ir kvėpavimą iki atvyks pagalba ir likite su žmogumi",
            "Monitored Workplaces": "Stebimos darbo vietos",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Kai tik įmanoma, perkelkite tiesioginį saulės poveikį ir sunkų darbą į šešėlį bei ribokite laiką tiesioginėje saulėje.",
            "No active topic subscriptions": "Nėra aktyvių temų prenumeratų",
            "No matching address found.": "Tinkamas adresas nerastas.",
            "No workplaces yet.": "Dar nėra darbo vietų.",
            "Open info": "Atidaryti informaciją",
            "Optional": "Nebūtina",
            "Organizational measures": "Organizacinės priemonės",
            "Peak UV": "Didžiausias UV",
            "Personal protective measures": "Asmeninės apsaugos priemonės",
            "Please enter an address.": "Įveskite adresą.",
            "Possible emergency measures": "Galimos skubios priemonės",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Užtikrinkite pakankamai geriamojo vandens
            Lengvi darbo drabužiai su UV apsauga ir apsauginiu kremu nuo saulės (rekomenduojamas SPF 50), akiniai su UV apsauga, vėsinantys rankšluosčiai
            Priklausomai nuo darbo srities: apsauginis šalmas su kaklo apsauga
            """,
            "Quick Glance": "Greita apžvalga",
            "Red": "Raudona",
            "Refresh data": "Atnaujinti duomenis",
            "Response plan (STOP principle)": "Veiksmų planas (STOP principas)",
            "Search Address": "Ieškoti adreso",
            "Search address or place": "Ieškoti adreso arba vietos",
            "Searching address...": "Ieškomas adresas...",
            "Settings": "Nustatymai",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Uždenkite darbo ir poilsio zonas (mobiliais) skėčiais, paviljonais ir pan.
            Naudokite technines vėsinimo priemones, tokias kaip ventiliatoriai
            Sumažinkite fiziškai sunkų darbą, pavyzdžiui, naudodami kėlimo priemones
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Keiskite darbo laiką: sunkų darbą planuokite vėsesnėmis ryto valandomis
            Suteikite tinkamas pertraukas atvėsimui
            Sunkius darbus atlikite šešėlyje arba vėsiose vietose
            """,
            "Stable": "Stabilus",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Nuo 2 karščio perspėjimo lygio (nuo 30 °C) turi būti įgyvendintas veiksmų planas ir skubios priemonės. Galimos priemonės apima:",
            "Stay informed": "Būkite informuoti",
            "Stop work and move the affected person to shade or a cool place": "Nutraukite darbą ir perkelkite nukentėjusįjį į šešėlį arba vėsią patalpą",
            "System": "Sistema",
            "System language": "Sistemos kalba",
            "Technical measures": "Techninės priemonės",
            "The workplace could not be added.": "Darbo vietos nepavyko pridėti.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Ši programėlės sesija dabar rodo atsitiktinius perspėjimo lygius visoms darbo vietoms. Režimas vėl išsijungs kitą kartą paleidus programėlę.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Ši teritorija tikriausiai yra už Austrijos ribų arba GeoSphere jos neatpažįsta. Pridėti negalima.",
            "Today": "Šiandien",
            "Topics": "Temos",
            "Traffic-light status, UV and workplaces live in one view.": "Šviesoforo būsena, UV ir darbo vietos gyvai viename rodinyje.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV indeksas >= 5",
            "UV Protection Measures": "UV apsaugos priemonės",
            "Unable to add": "Nepavyksta pridėti",
            "Warnings": "Įspėjimai",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Padedame laikytis teisinių reikalavimų dėl karščio ir natūralios UV spinduliuotės pavojų dirbant lauke. Visada stebėkite temperatūrą ir UV indeksą.",
            "Welcome to Hitze-V": "Sveiki atvykę į Hitze-V",
            "Workplaces": "Darbo vietos",
            "Yellow": "Geltona",
            "n/a": "nėra",
        ],
        .tr: [
            "Push notifications": "Push bildirimleri",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Sıcaklık uyarılarının push bildirimleri olarak gönderilip gönderilmeyeceğini ve hangi iş yerleri için gönderileceğini seçin.",
            "Enable push notifications": "Push bildirimlerini etkinleştir",
            "Worksites for push": "Push bildirimleri için iş yerleri",
            "Add a worksite first to control push notifications individually.": "Push bildirimlerini ayrı ayrı yönetmek için önce bir iş yeri ekleyin.",
            "No address available": "Adres mevcut değil",
            "Turning this off immediately removes all current push subscriptions.": "Bunu kapatmak mevcut tüm push aboneliklerini hemen kaldırır.",
            "2 (apparent temperature ≥ 30 °C)": "2 (hissedilen sıcaklık ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (hissedilen sıcaklık ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (hissedilen sıcaklık ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktif konu abonelikleri",
            "Add": "Ekle",
            "Address search failed. Please try again.": "Adres araması başarısız oldu. Lütfen tekrar deneyin.",
            "Adjust schedules and actively protect teams.": "Programları ayarlayın ve ekipleri aktif olarak koruyun.",
            "All clear. Standard precautions are sufficient.": "Her şey normal. Standart önlemler yeterlidir.",
            "All day": "Tüm gün",
            "Allow & Start": "İzin ver ve başlat",
            "Appearance": "Görünüm",
            "Apply Heat-V protective measures immediately.": "Heat-V koruma önlemlerini hemen uygulayın.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "UV indeksi 5 ve üzerindeyken maruziyet belirgin şekilde artar. Koruyucu kıyafet, başlık, güneş gözlüğü ve güneş kremi kullanın.",
            "Auto": "Otomatik",
            "Call 144 now": "Şimdi 144'ü ara",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Durum kısa sürede düzelmezse veya bilinç kaybı belirtileri varsa acil servisi (144) arayın",
            "Cancel": "İptal",
            "Choose a result": "Bir sonuç seçin",
            "City, Street...": "Şehir, sokak...",
            "Close": "Kapat",
            "Cool the body, e.g. with damp cloths or ventilation": "Vücudu nemli bezler, soğuk kompresler veya havalandırma ile serinletin",
            "Create New Workplace": "Yeni iş yeri oluştur",
            "Critical": "Kritik",
            "Current Risk": "Mevcut risk",
            "Dark": "Koyu",
            "Data source: GeoSphere Austria": "Veri kaynağı: GeoSphere Austria",
            "Delete workplace": "İş yerini sil",
            "Development": "Geliştirme",
            "Elevated": "Yükselmiş",
            "Emergency measures": "Acil önlemler",
            "Feels Like": "Hissedilen",
            "GeoSphere test URL": "GeoSphere test URL'si",
            "Green": "Yeşil",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Baş ağrısı, baş dönmesi, mide bulantısı
            Halsizlik, kramplar, bilinç bulanıklığı
            Sıcak, kuru cilt veya çok terli cilt
            Bilinç bozukluğu
            """,
            "Heat Protection Measures": "Sıcak koruma önlemleri",
            "Heat Safety at a Glance": "Bir bakışta sıcak güvenliği",
            "Heat protection checklist for businesses": "İşletmeler için sıcak koruma kontrol listesi",
            "Heat warning level": "Sıcak uyarı seviyesi",
            "Heat warning scale": "Sıcak uyarı ölçeği",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Sıcağa bağlı belirtiler şunları içerebilir",
            "High": "Yüksek",
            "If set, this URL is used instead of the GeoSphere server.": "Ayarlanmışsa GeoSphere sunucusu yerine bu URL kullanılır.",
            "If there is no normal breathing, start CPR immediately and get help": "Normal solunum yoksa hemen CPR'a başlayın ve yardım çağırın",
            "If unconscious, place the person in the recovery position": "Kişi bilinçsizse yan güvenli pozisyona getirin",
            "Increase breaks and shade usage.": "Molaları ve gölge kullanımını artırın.",
            "Info": "Bilgi",
            "Info & Legal": "Bilgi ve yasal",
            "Label (optional)": "Etiket (isteğe bağlı)",
            "Later / Skip": "Sonra / Atla",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Kişinin yavaşça içmesini sağlayın (su, çay, elektrolit çözeltileri)",
            "Light": "Açık",
            "Live data could not be loaded right now. Please try again later.": "Canlı veriler şu anda yüklenemedi. Lütfen daha sonra tekrar deneyin.",
            "Loading live data": "Canlı veriler yükleniyor",
            "Loosen clothing": "Kıyafetleri gevşetin",
            "Maximum values across all workplaces": "Tüm iş yerlerindeki en yüksek değerler",
            "Mock active": "Mock aktif",
            "Mock mode enabled": "Mock modu etkin",
            "Mock mode stays active until the app is restarted.": "Mock modu uygulama yeniden başlatılana kadar etkin kalır.",
            "Monitor consciousness and breathing until emergency services arrive": "Acil servis gelene kadar bilinci ve solunumu izleyin ve kişinin yanında kalın",
            "Monitored Workplaces": "İzlenen iş yerleri",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Doğrudan güneş maruziyetini ve yorucu işleri mümkün olduğunca gölgeye taşıyın ve tam güneşte geçirilen süreyi sınırlayın.",
            "No active topic subscriptions": "Aktif konu aboneliği yok",
            "No matching address found.": "Eşleşen adres bulunamadı.",
            "No workplaces yet.": "Henüz iş yeri yok.",
            "Open info": "Bilgiyi aç",
            "Optional": "İsteğe bağlı",
            "Organizational measures": "Organizasyonel önlemler",
            "Peak UV": "En yüksek UV",
            "Personal protective measures": "Kişisel koruyucu önlemler",
            "Please enter an address.": "Lütfen bir adres girin.",
            "Possible emergency measures": "Olası acil önlemler",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Yeterli içme suyu sağlayın
            UV korumalı hafif iş kıyafeti ve güneş koruyucu (SPF 50 önerilir), UV koruyucu gözlük, serinletici havlular
            Çalışma alanına bağlı olarak: ense korumalı koruyucu baret
            """,
            "Quick Glance": "Hızlı bakış",
            "Red": "Kırmızı",
            "Refresh data": "Verileri yenile",
            "Response plan (STOP principle)": "Müdahale planı (STOP ilkesi)",
            "Search Address": "Adres ara",
            "Search address or place": "Adres veya yer ara",
            "Searching address...": "Adres aranıyor...",
            "Settings": "Ayarlar",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Çalışma ve dinlenme alanlarını (taşınabilir) şemsiyeler, pavyonlar vb. ile gölgelendirin
            Vantilatörler gibi teknik serinletme önlemleri kullanın
            Kaldırma yardımcıları gibi araçlarla fiziksel olarak yorucu işleri azaltın
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Çalışma saatlerini kaydırın: ağır işleri serin sabah saatlerine planlayın
            Serinlemek için uygun molalar verin
            Ağır işleri gölgede veya serin alanlarda yapın
            """,
            "Stable": "Stabil",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Sıcak uyarı seviyesi 2'den itibaren (30 °C'den başlayarak) bir müdahale planı ve acil önlemler uygulanmalıdır. Olası önlemler şunları içerir:",
            "Stay informed": "Bilgili kalın",
            "Stop work and move the affected person to shade or a cool place": "Çalışmayı durdurun ve etkilenen kişiyi gölgeye veya serin bir odaya taşıyın",
            "System": "Sistem",
            "System language": "Sistem dili",
            "Technical measures": "Teknik önlemler",
            "The workplace could not be added.": "İş yeri eklenemedi.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Bu uygulama oturumu artık tüm iş yerleri için rastgele uyarı seviyeleri gösteriyor. Mod, bir sonraki yeniden başlatmada tekrar kapanacaktır.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Bu alan muhtemelen Avusturya dışında veya GeoSphere tarafından tanınmıyor. Ekleme mümkün değil.",
            "Today": "Bugün",
            "Topics": "Konular",
            "Traffic-light status, UV and workplaces live in one view.": "Trafik ışığı durumu, UV ve iş yerleri tek görünümde canlı olarak.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV İndeksi >= 5",
            "UV Protection Measures": "UV koruma önlemleri",
            "Unable to add": "Eklenemiyor",
            "Warnings": "Uyarılar",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Açık havada çalışma sırasında ısı ve doğal UV ışınımı risklerine ilişkin yasal gerekliliklere uymanıza yardımcı oluyoruz. Sıcaklıkları ve UV indeksini her zaman takip edin.",
            "Welcome to Hitze-V": "Hitze-V'ye hoş geldiniz",
            "Workplaces": "İş yerleri",
            "Yellow": "Sarı",
            "n/a": "yok",
        ],
        .pl: [
            "Push notifications": "Powiadomienia push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Wybierz, czy ostrzeżenia o upale mają być wysyłane jako powiadomienia push i dla których miejsc pracy.",
            "Enable push notifications": "Włącz powiadomienia push",
            "Worksites for push": "Miejsca pracy dla powiadomień push",
            "Add a worksite first to control push notifications individually.": "Najpierw dodaj miejsce pracy, aby zarządzać powiadomieniami push osobno.",
            "No address available": "Brak dostępnego adresu",
            "Turning this off immediately removes all current push subscriptions.": "Wyłączenie tej opcji natychmiast usuwa wszystkie bieżące subskrypcje push.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatura odczuwalna ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatura odczuwalna ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatura odczuwalna ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktywne subskrypcje tematów",
            "Add": "Dodaj",
            "Address search failed. Please try again.": "Wyszukiwanie adresu nie powiodło się. Spróbuj ponownie.",
            "Adjust schedules and actively protect teams.": "Dostosuj harmonogramy i aktywnie chroń zespoły.",
            "All clear. Standard precautions are sufficient.": "Wszystko w porządku. Standardowe środki ostrożności są wystarczające.",
            "All day": "Cały dzień",
            "Allow & Start": "Zezwól i rozpocznij",
            "Appearance": "Wygląd",
            "Apply Heat-V protective measures immediately.": "Natychmiast zastosuj środki ochronne Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Przy indeksie UV 5 i wyższym ekspozycja znacząco rośnie. Konsekwentnie używaj odzieży ochronnej, nakrycia głowy, okularów przeciwsłonecznych i kremu z filtrem.",
            "Auto": "Auto",
            "Call 144 now": "Zadzwoń teraz pod 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Zadzwoń na pogotowie (144), jeśli stan nie poprawi się wkrótce lub pojawią się oznaki utraty przytomności",
            "Cancel": "Anuluj",
            "Choose a result": "Wybierz wynik",
            "City, Street...": "Miasto, ulica...",
            "Close": "Zamknij",
            "Cool the body, e.g. with damp cloths or ventilation": "Ochłodź ciało wilgotnymi ściereczkami, zimnymi okładami lub wentylacją",
            "Create New Workplace": "Utwórz nowe miejsce pracy",
            "Critical": "Krytyczny",
            "Current Risk": "Aktualne ryzyko",
            "Dark": "Ciemny",
            "Data source: GeoSphere Austria": "Źródło danych: GeoSphere Austria",
            "Delete workplace": "Usuń miejsce pracy",
            "Development": "Rozwój",
            "Elevated": "Podwyższony",
            "Emergency measures": "Działania ratunkowe",
            "Feels Like": "Temperatura odczuwalna",
            "GeoSphere test URL": "Testowy URL GeoSphere",
            "Green": "Zielony",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Bóle głowy, zawroty głowy, nudności
            Osłabienie, skurcze, dezorientacja
            Gorąca, sucha skóra lub bardzo spocona skóra
            Zaburzenia świadomości
            """,
            "Heat Protection Measures": "Środki ochrony przed upałem",
            "Heat Safety at a Glance": "Bezpieczeństwo w upale w skrócie",
            "Heat protection checklist for businesses": "Lista kontrolna ochrony przed upałem dla firm",
            "Heat warning level": "Poziom ostrzeżenia przed upałem",
            "Heat warning scale": "Skala ostrzeżeń przed upałem",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Objawy związane z upałem mogą obejmować",
            "High": "Wysoki",
            "If set, this URL is used instead of the GeoSphere server.": "Jeśli ustawiono, ten adres URL jest używany zamiast serwera GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Jeśli nie ma prawidłowego oddechu, natychmiast rozpocznij resuscytację i wezwij pomoc",
            "If unconscious, place the person in the recovery position": "Jeśli osoba jest nieprzytomna, ułóż ją w pozycji bezpiecznej",
            "Increase breaks and shade usage.": "Zwiększ liczbę przerw i korzystanie z cienia.",
            "Info": "Informacje",
            "Info & Legal": "Informacje i kwestie prawne",
            "Label (optional)": "Etykieta (opcjonalnie)",
            "Later / Skip": "Później / Pomiń",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Pozwól osobie pić powoli (wodę, herbatę, roztwory elektrolitowe)",
            "Light": "Jasny",
            "Live data could not be loaded right now. Please try again later.": "Nie udało się teraz załadować danych na żywo. Spróbuj ponownie później.",
            "Loading live data": "Ładowanie danych na żywo",
            "Loosen clothing": "Poluzuj odzież",
            "Maximum values across all workplaces": "Maksymalne wartości we wszystkich miejscach pracy",
            "Mock active": "Mock aktywny",
            "Mock mode enabled": "Tryb mock włączony",
            "Mock mode stays active until the app is restarted.": "Tryb mock pozostaje aktywny do ponownego uruchomienia aplikacji.",
            "Monitor consciousness and breathing until emergency services arrive": "Monitoruj świadomość i oddech do przyjazdu pogotowia i pozostań z poszkodowanym",
            "Monitored Workplaces": "Monitorowane miejsca pracy",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "W miarę możliwości przenieś bezpośrednią ekspozycję na słońce i ciężką pracę do cienia oraz ogranicz czas spędzany w pełnym słońcu.",
            "No active topic subscriptions": "Brak aktywnych subskrypcji tematów",
            "No matching address found.": "Nie znaleziono pasującego adresu.",
            "No workplaces yet.": "Nie ma jeszcze żadnych miejsc pracy.",
            "Open info": "Otwórz informacje",
            "Optional": "Opcjonalnie",
            "Organizational measures": "Środki organizacyjne",
            "Peak UV": "Szczyt UV",
            "Personal protective measures": "Środki ochrony osobistej",
            "Please enter an address.": "Wprowadź adres.",
            "Possible emergency measures": "Możliwe działania ratunkowe",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Zapewnij wystarczającą ilość wody pitnej
            Lekka odzież robocza z ochroną UV i kremem przeciwsłonecznym (zalecany SPF 50), okulary z ochroną UV, ręczniki chłodzące
            W zależności od obszaru pracy: kask ochronny z osłoną karku
            """,
            "Quick Glance": "Szybki podgląd",
            "Red": "Czerwony",
            "Refresh data": "Odśwież dane",
            "Response plan (STOP principle)": "Plan działań (zasada STOP)",
            "Search Address": "Szukaj adresu",
            "Search address or place": "Szukaj adresu lub miejsca",
            "Searching address...": "Wyszukiwanie adresu...",
            "Settings": "Ustawienia",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Zacieniaj miejsca pracy i odpoczynku za pomocą (mobilnych) parasoli, pawilonów itp.
            Stosuj techniczne środki chłodzenia, takie jak wentylatory
            Ogranicz fizycznie ciężką pracę, np. dzięki użyciu pomocy do podnoszenia
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Przesuń godziny pracy: planuj ciężkie prace na chłodniejsze godziny poranne
            Zapewnij odpowiednie przerwy na schłodzenie
            Wykonuj ciężkie zadania w cieniu lub w chłodnych miejscach
            """,
            "Stable": "Stabilny",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Od poziomu ostrzeżenia przed upałem 2 (od 30 °C) należy wdrożyć plan działań i środki ratunkowe. Możliwe środki obejmują:",
            "Stay informed": "Bądź na bieżąco",
            "Stop work and move the affected person to shade or a cool place": "Przerwij pracę i przenieś poszkodowaną osobę do cienia lub chłodnego pomieszczenia",
            "System": "System",
            "System language": "Język systemu",
            "Technical measures": "Środki techniczne",
            "The workplace could not be added.": "Nie udało się dodać miejsca pracy.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Ta sesja aplikacji pokazuje teraz losowe poziomy ostrzeżeń dla wszystkich miejsc pracy. Tryb wyłączy się ponownie przy następnym uruchomieniu.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Ten obszar prawdopodobnie znajduje się poza Austrią lub nie jest rozpoznawany przez GeoSphere. Dodanie nie jest możliwe.",
            "Today": "Dzisiaj",
            "Topics": "Tematy",
            "Traffic-light status, UV and workplaces live in one view.": "Status sygnalizacji, UV i miejsca pracy na żywo w jednym widoku.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Indeks UV >= 5",
            "UV Protection Measures": "Środki ochrony UV",
            "Unable to add": "Nie można dodać",
            "Warnings": "Ostrzeżenia",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Pomagamy spełniać wymogi prawne dotyczące zagrożeń związanych z upałem i naturalnym promieniowaniem UV przy pracy na zewnątrz. Zawsze monitoruj temperaturę i indeks UV.",
            "Welcome to Hitze-V": "Witamy w Hitze-V",
            "Workplaces": "Miejsca pracy",
            "Yellow": "Żółty",
            "n/a": "n/d",
        ],
        .hu: [
            "Push notifications": "Push értesítések",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Válaszd ki, hogy a hőségriasztások push értesítésként legyenek-e elküldve, és mely munkahelyekre.",
            "Enable push notifications": "Push értesítések engedélyezése",
            "Worksites for push": "Munkahelyek push értesítésekhez",
            "Add a worksite first to control push notifications individually.": "Először adj hozzá egy munkahelyet, hogy külön kezeld a push értesítéseket.",
            "No address available": "Nincs elérhető cím",
            "Turning this off immediately removes all current push subscriptions.": "Ha ezt kikapcsolod, az összes jelenlegi push-feliratkozás azonnal megszűnik.",
            "2 (apparent temperature ≥ 30 °C)": "2 (érzett hőmérséklet ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (érzett hőmérséklet ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (érzett hőmérséklet ≥ 40 °C)",
            "Active Topic Subscriptions": "Aktív témakövetések",
            "Add": "Hozzáadás",
            "Address search failed. Please try again.": "A címkeresés nem sikerült. Kérjük, próbálja újra.",
            "Adjust schedules and actively protect teams.": "Igazítsa az időbeosztásokat és védje aktívan a csapatokat.",
            "All clear. Standard precautions are sufficient.": "Minden rendben. A szokásos óvintézkedések elegendőek.",
            "All day": "Egész nap",
            "Allow & Start": "Engedélyezés és indítás",
            "Appearance": "Megjelenés",
            "Apply Heat-V protective measures immediately.": "Azonnal vezesse be a Heat-V védelmi intézkedéseket.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "5-ös vagy magasabb UV-indexnél a terhelés jelentősen nő. Következetesen használjon védőruházatot, fejfedőt, napszemüveget és naptejet.",
            "Auto": "Automatikus",
            "Call 144 now": "Hívja most a 144-et",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Hívja a sürgősségi szolgálatot (144), ha az állapot nem javul hamarosan vagy eszméletvesztés jelei mutatkoznak",
            "Cancel": "Mégse",
            "Choose a result": "Válasszon egy találatot",
            "City, Street...": "Város, utca...",
            "Close": "Bezárás",
            "Cool the body, e.g. with damp cloths or ventilation": "Hűtse a testet nedves törlőkendőkkel, hideg borogatással vagy szellőztetéssel",
            "Create New Workplace": "Új munkahely létrehozása",
            "Critical": "Kritikus",
            "Current Risk": "Jelenlegi kockázat",
            "Dark": "Sötét",
            "Data source: GeoSphere Austria": "Adatforrás: GeoSphere Austria",
            "Delete workplace": "Munkahely törlése",
            "Development": "Fejlesztés",
            "Elevated": "Emelkedett",
            "Emergency measures": "Sürgősségi intézkedések",
            "Feels Like": "Érzett hőmérséklet",
            "GeoSphere test URL": "GeoSphere teszt URL",
            "Green": "Zöld",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Fejfájás, szédülés, hányinger
            Gyengeség, görcsök, zavartság
            Forró, száraz bőr vagy nagyon izzadt bőr
            Tudatzavar
            """,
            "Heat Protection Measures": "Hővédelmi intézkedések",
            "Heat Safety at a Glance": "Hőbiztonság egy pillantásra",
            "Heat protection checklist for businesses": "Hővédelmi ellenőrzőlista vállalkozásoknak",
            "Heat warning level": "Hőségriasztási szint",
            "Heat warning scale": "Hőségriasztási skála",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "A hővel összefüggő tünetek közé tartozhat",
            "High": "Magas",
            "If set, this URL is used instead of the GeoSphere server.": "Ha be van állítva, a GeoSphere szerver helyett ez az URL kerül használatra.",
            "If there is no normal breathing, start CPR immediately and get help": "Ha nincs normális légzés, azonnal kezdje meg az újraélesztést és hívjon segítséget",
            "If unconscious, place the person in the recovery position": "Ha a személy eszméletlen, helyezze stabil oldalfekvésbe",
            "Increase breaks and shade usage.": "Növelje a pihenőidőket és az árnyék használatát.",
            "Info": "Információ",
            "Info & Legal": "Információ és jogi tudnivalók",
            "Label (optional)": "Címke (opcionális)",
            "Later / Skip": "Később / Kihagyás",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Lassan itassa a személyt (víz, tea, elektrolitoldatok)",
            "Light": "Világos",
            "Live data could not be loaded right now. Please try again later.": "Az élő adatok jelenleg nem tölthetők be. Kérjük, próbálja újra később.",
            "Loading live data": "Élő adatok betöltése",
            "Loosen clothing": "Lazítsa meg a ruházatot",
            "Maximum values across all workplaces": "Maximális értékek az összes munkahelyen",
            "Mock active": "Mock aktív",
            "Mock mode enabled": "Mock mód engedélyezve",
            "Mock mode stays active until the app is restarted.": "A mock mód az alkalmazás újraindításáig aktív marad.",
            "Monitor consciousness and breathing until emergency services arrive": "Figyelje a tudatállapotot és a légzést a mentők megérkezéséig, és maradjon a személy mellett",
            "Monitored Workplaces": "Felügyelt munkahelyek",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "A közvetlen napsugárzást és a megterhelő munkát lehetőség szerint helyezze árnyékba, és korlátozza a tűző napon töltött időt.",
            "No active topic subscriptions": "Nincsenek aktív témakövetések",
            "No matching address found.": "Nem található megfelelő cím.",
            "No workplaces yet.": "Még nincsenek munkahelyek.",
            "Open info": "Információ megnyitása",
            "Optional": "Opcionális",
            "Organizational measures": "Szervezési intézkedések",
            "Peak UV": "Legmagasabb UV",
            "Personal protective measures": "Egyéni védelmi intézkedések",
            "Please enter an address.": "Adjon meg egy címet.",
            "Possible emergency measures": "Lehetséges sürgősségi intézkedések",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Biztosítson elegendő ivóvizet
            Könnyű munkaruha UV-védelemmel és napvédő krémmel (SPF 50 ajánlott), UV-védőszemüveg, hűtőtörölközők
            Munkaterülettől függően: védősisak nyakvédelemmel
            """,
            "Quick Glance": "Gyors áttekintés",
            "Red": "Piros",
            "Refresh data": "Adatok frissítése",
            "Response plan (STOP principle)": "Intézkedési terv (STOP-elv)",
            "Search Address": "Cím keresése",
            "Search address or place": "Cím vagy hely keresése",
            "Searching address...": "Cím keresése...",
            "Settings": "Beállítások",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Árnyékolja a munka- és pihenőterületeket (mobil) napernyőkkel, pavilonokkal stb.
            Használjon technikai hűtési intézkedéseket, például ventilátorokat
            Csökkentse a fizikailag megterhelő munkát, például emelőeszközök használatával
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Tolja el a munkaidőt: a nehéz munkát a hűvösebb reggeli órákra időzítse
            Biztosítson megfelelő szüneteket a lehűléshez
            A nehéz feladatokat árnyékban vagy hűvös helyen végezze
            """,
            "Stable": "Stabil",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "A 2-es hőségriasztási szinttől (30 °C-tól) intézkedési tervet és sürgősségi intézkedéseket kell bevezetni. A lehetséges intézkedések többek között:",
            "Stay informed": "Maradjon tájékozott",
            "Stop work and move the affected person to shade or a cool place": "Állítsa le a munkát, és vigye az érintett személyt árnyékba vagy hűvös helyiségbe",
            "System": "Rendszer",
            "System language": "Rendszernyelv",
            "Technical measures": "Műszaki intézkedések",
            "The workplace could not be added.": "A munkahelyet nem sikerült hozzáadni.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Ez az alkalmazásmunkamenet most minden munkahelyhez véletlenszerű figyelmeztetési szinteket mutat. A mód a következő újraindításkor ismét kikapcsol.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Ez a terület valószínűleg Ausztrián kívül van, vagy a GeoSphere nem ismeri fel. Hozzáadás nem lehetséges.",
            "Today": "Ma",
            "Topics": "Témák",
            "Traffic-light status, UV and workplaces live in one view.": "Jelzőlámpa-állapot, UV és munkahelyek élőben egy nézetben.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV-index >= 5",
            "UV Protection Measures": "UV-védelmi intézkedések",
            "Unable to add": "Nem lehet hozzáadni",
            "Warnings": "Figyelmeztetések",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Segítünk megfelelni a szabadtéri munkát érintő hő- és természetes UV-sugárzási kockázatokra vonatkozó jogi követelményeknek. Mindig figyeld a hőmérsékletet és az UV-indexet.",
            "Welcome to Hitze-V": "Üdvözli a Hitze-V",
            "Workplaces": "Munkahelyek",
            "Yellow": "Sárga",
            "n/a": "n.a.",
        ],
        .bg: [
            "Push notifications": "Push известия",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Изберете дали предупрежденията за горещини да се изпращат като push известия и за кои работни места.",
            "Enable push notifications": "Активиране на push известия",
            "Worksites for push": "Работни места за push",
            "Add a worksite first to control push notifications individually.": "Първо добавете работно място, за да управлявате push известията поотделно.",
            "No address available": "Няма наличен адрес",
            "Turning this off immediately removes all current push subscriptions.": "Изключването на тази настройка незабавно премахва всички текущи push абонаменти.",
            "2 (apparent temperature ≥ 30 °C)": "2 (усещана температура ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (усещана температура ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (усещана температура ≥ 40 °C)",
            "Active Topic Subscriptions": "Активни абонаменти за теми",
            "Add": "Добавяне",
            "Address search failed. Please try again.": "Търсенето на адрес не бе успешно. Моля, опитайте отново.",
            "Adjust schedules and actively protect teams.": "Коригирайте графиците и активно защитете екипите.",
            "All clear. Standard precautions are sufficient.": "Всичко е спокойно. Стандартните предпазни мерки са достатъчни.",
            "All day": "Цял ден",
            "Allow & Start": "Разрешаване и старт",
            "Appearance": "Външен вид",
            "Apply Heat-V protective measures immediately.": "Незабавно приложете защитните мерки Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "При UV индекс 5 и повече излагането значително се увеличава. Последователно използвайте защитно облекло, покривало за глава, слънчеви очила и слънцезащитен крем.",
            "Auto": "Авто",
            "Call 144 now": "Обадете се на 144 сега",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Обадете се на спешна помощ (144), ако състоянието скоро не се подобри или има признаци на загуба на съзнание",
            "Cancel": "Отказ",
            "Choose a result": "Изберете резултат",
            "City, Street...": "Град, улица...",
            "Close": "Затвори",
            "Cool the body, e.g. with damp cloths or ventilation": "Охладете тялото с влажни кърпи, студени компреси или вентилация",
            "Create New Workplace": "Създаване на ново работно място",
            "Critical": "Критично",
            "Current Risk": "Текущ риск",
            "Dark": "Тъмен",
            "Data source: GeoSphere Austria": "Източник на данни: GeoSphere Austria",
            "Delete workplace": "Изтриване на работно място",
            "Development": "Разработка",
            "Elevated": "Повишен",
            "Emergency measures": "Спешни мерки",
            "Feels Like": "Усеща се като",
            "GeoSphere test URL": "Тестов URL на GeoSphere",
            "Green": "Зелено",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Главоболие, замайване, гадене
            Слабост, крампи, обърканост
            Гореща, суха кожа или много изпотена кожа
            Нарушено съзнание
            """,
            "Heat Protection Measures": "Мерки за защита от жега",
            "Heat Safety at a Glance": "Безопасност при жега с един поглед",
            "Heat protection checklist for businesses": "Контролен списък за защита от жега за фирми",
            "Heat warning level": "Ниво на предупреждение за жега",
            "Heat warning scale": "Скала на предупрежденията за жега",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Симптомите, свързани с жегата, могат да включват",
            "High": "Висок",
            "If set, this URL is used instead of the GeoSphere server.": "Ако е зададен, този URL се използва вместо сървъра на GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Ако няма нормално дишане, незабавно започнете сърдечен масаж и повикайте помощ",
            "If unconscious, place the person in the recovery position": "Ако човекът е в безсъзнание, поставете го в стабилно странично положение",
            "Increase breaks and shade usage.": "Увеличете почивките и използването на сянка.",
            "Info": "Информация",
            "Info & Legal": "Информация и правни данни",
            "Label (optional)": "Етикет (по избор)",
            "Later / Skip": "По-късно / Пропускане",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Нека човекът пие бавно (вода, чай, електролитни разтвори)",
            "Light": "Светъл",
            "Live data could not be loaded right now. Please try again later.": "Данните на живо не могат да бъдат заредени в момента. Моля, опитайте отново по-късно.",
            "Loading live data": "Зареждане на данни на живо",
            "Loosen clothing": "Разхлабете дрехите",
            "Maximum values across all workplaces": "Максимални стойности за всички работни места",
            "Mock active": "Mock активен",
            "Mock mode enabled": "Mock режимът е активиран",
            "Mock mode stays active until the app is restarted.": "Mock режимът остава активен до рестартиране на приложението.",
            "Monitor consciousness and breathing until emergency services arrive": "Наблюдавайте съзнанието и дишането до пристигането на спешна помощ и останете до човека",
            "Monitored Workplaces": "Наблюдавани работни места",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Когато е възможно, преместете прякото излагане на слънце и тежката работа на сянка и ограничете времето на силно слънце.",
            "No active topic subscriptions": "Няма активни абонаменти за теми",
            "No matching address found.": "Не е намерен съвпадащ адрес.",
            "No workplaces yet.": "Все още няма работни места.",
            "Open info": "Отвори информация",
            "Optional": "По избор",
            "Organizational measures": "Организационни мерки",
            "Peak UV": "Най-висок UV",
            "Personal protective measures": "Лични защитни мерки",
            "Please enter an address.": "Моля, въведете адрес.",
            "Possible emergency measures": "Възможни спешни мерки",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Осигурете достатъчно питейна вода
            Леко работно облекло с UV защита и слънцезащитен продукт (препоръчва се SPF 50), UV защитни очила, охлаждащи кърпи
            Според работната зона: предпазна каска със защита за врата
            """,
            "Quick Glance": "Бърз преглед",
            "Red": "Червено",
            "Refresh data": "Обновяване на данните",
            "Response plan (STOP principle)": "План за действие (принцип STOP)",
            "Search Address": "Търсене на адрес",
            "Search address or place": "Търсене на адрес или място",
            "Searching address...": "Търсене на адрес...",
            "Settings": "Настройки",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Осигурете сянка за работните и почивните места с (мобилни) чадъри, павилиони и др.
            Използвайте технически мерки за охлаждане като вентилатори
            Намалете физически тежката работа, напр. чрез помощни средства за повдигане
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Изместете работното време: планирайте тежката работа в по-хладните сутрешни часове
            Осигурете подходящи почивки за охлаждане
            Изпълнявайте тежките задачи на сянка или в хладни зони
            """,
            "Stable": "Стабилно",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "От ниво 2 на предупреждение за жега (от 30 °C) трябва да бъдат въведени план за действие и спешни мерки. Възможните мерки включват:",
            "Stay informed": "Бъдете информирани",
            "Stop work and move the affected person to shade or a cool place": "Прекратете работата и преместете засегнатия човек на сянка или в хладно помещение",
            "System": "Система",
            "System language": "Системен език",
            "Technical measures": "Технически мерки",
            "The workplace could not be added.": "Работното място не можа да бъде добавено.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Тази сесия на приложението вече показва случайни нива на предупреждение за всички работни места. Режимът ще се изключи отново при следващото стартиране.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Този район вероятно е извън Австрия или не се разпознава от GeoSphere. Добавянето не е възможно.",
            "Today": "Днес",
            "Topics": "Теми",
            "Traffic-light status, UV and workplaces live in one view.": "Светофарен статус, UV и работни места на живо в един изглед.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "UV индекс >= 5",
            "UV Protection Measures": "Мерки за UV защита",
            "Unable to add": "Не може да се добави",
            "Warnings": "Предупреждения",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Помагаме ви да спазвате законовите изисквания за рисковете от жега и естествено UV лъчение при работа на открито. Следете постоянно температурите и UV индекса.",
            "Welcome to Hitze-V": "Добре дошли в Hitze-V",
            "Workplaces": "Работни места",
            "Yellow": "Жълто",
            "n/a": "няма",
        ],
        .el: [
            "Push notifications": "Ειδοποιήσεις push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Επιλέξτε αν οι προειδοποιήσεις ζέστης θα αποστέλλονται ως ειδοποιήσεις push και για ποιους χώρους εργασίας.",
            "Enable push notifications": "Ενεργοποίηση ειδοποιήσεων push",
            "Worksites for push": "Χώροι εργασίας για push",
            "Add a worksite first to control push notifications individually.": "Προσθέστε πρώτα έναν χώρο εργασίας για να διαχειρίζεστε ξεχωριστά τις ειδοποιήσεις push.",
            "No address available": "Δεν υπάρχει διαθέσιμη διεύθυνση",
            "Turning this off immediately removes all current push subscriptions.": "Η απενεργοποίηση αφαιρεί αμέσως όλες τις τρέχουσες συνδρομές push.",
            "2 (apparent temperature ≥ 30 °C)": "2 (αισθητή θερμοκρασία ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (αισθητή θερμοκρασία ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (αισθητή θερμοκρασία ≥ 40 °C)",
            "Active Topic Subscriptions": "Ενεργές συνδρομές θεμάτων",
            "Add": "Προσθήκη",
            "Address search failed. Please try again.": "Η αναζήτηση διεύθυνσης απέτυχε. Προσπαθήστε ξανά.",
            "Adjust schedules and actively protect teams.": "Προσαρμόστε τα προγράμματα και προστατέψτε ενεργά τις ομάδες.",
            "All clear. Standard precautions are sufficient.": "Όλα είναι εντάξει. Τα συνήθη μέτρα προφύλαξης αρκούν.",
            "All day": "Όλη την ημέρα",
            "Allow & Start": "Να επιτραπεί και να ξεκινήσει",
            "Appearance": "Εμφάνιση",
            "Apply Heat-V protective measures immediately.": "Εφαρμόστε αμέσως τα μέτρα προστασίας Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Σε δείκτη UV 5 και άνω, η έκθεση αυξάνεται σημαντικά. Χρησιμοποιείτε σταθερά προστατευτικό ρουχισμό, κάλυμμα κεφαλής, γυαλιά ηλίου και αντηλιακό.",
            "Auto": "Αυτόματο",
            "Call 144 now": "Καλέστε τώρα το 144",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Καλέστε τις υπηρεσίες έκτακτης ανάγκης (144) αν η κατάσταση δεν βελτιωθεί σύντομα ή αν υπάρχουν σημάδια απώλειας συνείδησης",
            "Cancel": "Ακύρωση",
            "Choose a result": "Επιλέξτε αποτέλεσμα",
            "City, Street...": "Πόλη, οδός...",
            "Close": "Κλείσιμο",
            "Cool the body, e.g. with damp cloths or ventilation": "Δροσίστε το σώμα με υγρά πανιά, κρύες κομπρέσες ή αερισμό",
            "Create New Workplace": "Δημιουργία νέου χώρου εργασίας",
            "Critical": "Κρίσιμο",
            "Current Risk": "Τρέχων κίνδυνος",
            "Dark": "Σκούρο",
            "Data source: GeoSphere Austria": "Πηγή δεδομένων: GeoSphere Austria",
            "Delete workplace": "Διαγραφή χώρου εργασίας",
            "Development": "Ανάπτυξη",
            "Elevated": "Αυξημένο",
            "Emergency measures": "Επείγοντα μέτρα",
            "Feels Like": "Αίσθηση θερμοκρασίας",
            "GeoSphere test URL": "Δοκιμαστικό URL GeoSphere",
            "Green": "Πράσινο",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Πονοκέφαλος, ζάλη, ναυτία
            Αδυναμία, κράμπες, σύγχυση
            Ζεστό και ξηρό δέρμα ή πολύ ιδρωμένο δέρμα
            Διαταραχή συνείδησης
            """,
            "Heat Protection Measures": "Μέτρα προστασίας από τη ζέστη",
            "Heat Safety at a Glance": "Ασφάλεια στη ζέστη με μια ματιά",
            "Heat protection checklist for businesses": "Λίστα ελέγχου προστασίας από τη ζέστη για επιχειρήσεις",
            "Heat warning level": "Επίπεδο προειδοποίησης ζέστης",
            "Heat warning scale": "Κλίμακα προειδοποίησης ζέστης",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Τα συμπτώματα που σχετίζονται με τη ζέστη μπορεί να περιλαμβάνουν",
            "High": "Υψηλό",
            "If set, this URL is used instead of the GeoSphere server.": "Αν έχει οριστεί, αυτό το URL χρησιμοποιείται αντί για τον διακομιστή GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Αν δεν υπάρχει φυσιολογική αναπνοή, ξεκινήστε αμέσως ΚΑΡΠΑ και ζητήστε βοήθεια",
            "If unconscious, place the person in the recovery position": "Αν το άτομο είναι αναίσθητο, βάλτε το σε θέση ανάνηψης",
            "Increase breaks and shade usage.": "Αυξήστε τα διαλείμματα και τη χρήση σκιάς.",
            "Info": "Πληροφορίες",
            "Info & Legal": "Πληροφορίες και νομικά",
            "Label (optional)": "Ετικέτα (προαιρετικό)",
            "Later / Skip": "Αργότερα / Παράλειψη",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Αφήστε το άτομο να πιει αργά (νερό, τσάι, διαλύματα ηλεκτρολυτών)",
            "Light": "Φωτεινό",
            "Live data could not be loaded right now. Please try again later.": "Τα ζωντανά δεδομένα δεν μπόρεσαν να φορτωθούν αυτή τη στιγμή. Προσπαθήστε ξανά αργότερα.",
            "Loading live data": "Φόρτωση ζωντανών δεδομένων",
            "Loosen clothing": "Χαλαρώστε τα ρούχα",
            "Maximum values across all workplaces": "Μέγιστες τιμές σε όλους τους χώρους εργασίας",
            "Mock active": "Mock ενεργό",
            "Mock mode enabled": "Η λειτουργία mock ενεργοποιήθηκε",
            "Mock mode stays active until the app is restarted.": "Η λειτουργία mock παραμένει ενεργή μέχρι να γίνει επανεκκίνηση της εφαρμογής.",
            "Monitor consciousness and breathing until emergency services arrive": "Παρακολουθήστε τη συνείδηση και την αναπνοή μέχρι να φτάσουν οι υπηρεσίες έκτακτης ανάγκης και μείνετε με το άτομο",
            "Monitored Workplaces": "Παρακολουθούμενοι χώροι εργασίας",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Μεταφέρετε την άμεση έκθεση στον ήλιο και τη βαριά εργασία στη σκιά όπου είναι δυνατόν και περιορίστε τον χρόνο στον έντονο ήλιο.",
            "No active topic subscriptions": "Δεν υπάρχουν ενεργές συνδρομές θεμάτων",
            "No matching address found.": "Δεν βρέθηκε αντίστοιχη διεύθυνση.",
            "No workplaces yet.": "Δεν υπάρχουν ακόμη χώροι εργασίας.",
            "Open info": "Άνοιγμα πληροφοριών",
            "Optional": "Προαιρετικό",
            "Organizational measures": "Οργανωτικά μέτρα",
            "Peak UV": "Μέγιστο UV",
            "Personal protective measures": "Ατομικά προστατευτικά μέτρα",
            "Please enter an address.": "Παρακαλώ εισάγετε μια διεύθυνση.",
            "Possible emergency measures": "Πιθανά επείγοντα μέτρα",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Παρέχετε επαρκές πόσιμο νερό
            Ελαφριά ενδυμασία εργασίας με προστασία UV και αντηλιακό (συνιστάται SPF 50), γυαλιά προστασίας UV, δροσιστικές πετσέτες
            Ανάλογα με τον χώρο εργασίας: προστατευτικό κράνος με προστασία αυχένα
            """,
            "Quick Glance": "Γρήγορη επισκόπηση",
            "Red": "Κόκκινο",
            "Refresh data": "Ανανέωση δεδομένων",
            "Response plan (STOP principle)": "Σχέδιο δράσης (αρχή STOP)",
            "Search Address": "Αναζήτηση διεύθυνσης",
            "Search address or place": "Αναζήτηση διεύθυνσης ή τοποθεσίας",
            "Searching address...": "Αναζήτηση διεύθυνσης...",
            "Settings": "Ρυθμίσεις",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Σκιάστε τους χώρους εργασίας και ανάπαυσης με (κινητές) ομπρέλες, περίπτερα κ.λπ.
            Χρησιμοποιήστε τεχνικά μέτρα ψύξης, όπως ανεμιστήρες
            Μειώστε τη σωματικά απαιτητική εργασία, π.χ. με βοηθήματα ανύψωσης
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Μετακινήστε τις ώρες εργασίας: προγραμματίστε τη βαριά εργασία στις πιο δροσερές πρωινές ώρες
            Παρέχετε κατάλληλα διαλείμματα για δροσιά
            Εκτελέστε τις βαριές εργασίες σε σκιά ή σε δροσερούς χώρους
            """,
            "Stable": "Σταθερό",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Από το επίπεδο προειδοποίησης ζέστης 2 (από 30 °C) πρέπει να εφαρμοστεί σχέδιο δράσης και επείγοντα μέτρα. Πιθανά μέτρα περιλαμβάνουν:",
            "Stay informed": "Μείνετε ενημερωμένοι",
            "Stop work and move the affected person to shade or a cool place": "Σταματήστε την εργασία και μεταφέρετε το επηρεασμένο άτομο στη σκιά ή σε δροσερό χώρο",
            "System": "Σύστημα",
            "System language": "Γλώσσα συστήματος",
            "Technical measures": "Τεχνικά μέτρα",
            "The workplace could not be added.": "Ο χώρος εργασίας δεν μπόρεσε να προστεθεί.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Αυτή η συνεδρία της εφαρμογής εμφανίζει τώρα τυχαία επίπεδα προειδοποίησης για όλους τους χώρους εργασίας. Η λειτουργία θα απενεργοποιηθεί ξανά στην επόμενη επανεκκίνηση.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Αυτή η περιοχή πιθανότατα βρίσκεται εκτός Αυστρίας ή δεν αναγνωρίζεται από το GeoSphere. Η προσθήκη δεν είναι δυνατή.",
            "Today": "Σήμερα",
            "Topics": "Θέματα",
            "Traffic-light status, UV and workplaces live in one view.": "Κατάσταση φωτεινού σηματοδότη, UV και χώροι εργασίας ζωντανά σε μία προβολή.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Δείκτης UV >= 5",
            "UV Protection Measures": "Μέτρα προστασίας UV",
            "Unable to add": "Δεν είναι δυνατή η προσθήκη",
            "Warnings": "Προειδοποιήσεις",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Σας βοηθάμε να συμμορφώνεστε με τις νομικές απαιτήσεις σχετικά με τους κινδύνους από τη ζέστη και τη φυσική υπεριώδη ακτινοβολία στην υπαίθρια εργασία. Παρακολουθείτε πάντα τη θερμοκρασία και τον δείκτη UV.",
            "Welcome to Hitze-V": "Καλώς ήρθατε στο Hitze-V",
            "Workplaces": "Χώροι εργασίας",
            "Yellow": "Κίτρινο",
            "n/a": "δ/υ",
        ],
        .ga: [
            "Push notifications": "Fógraí brú",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Roghnaigh an seolfar foláirimh teasa mar fhógraí brú agus do na hionaid oibre a gheobhaidh iad.",
            "Enable push notifications": "Cumasaigh fógraí brú",
            "Worksites for push": "Ionaid oibre le haghaidh fógraí brú",
            "Add a worksite first to control push notifications individually.": "Cuir láthair oibre leis ar dtús chun fógraí brú a bhainistiú ina n-aonar.",
            "No address available": "Níl seoladh ar fáil",
            "Turning this off immediately removes all current push subscriptions.": "Má mhúchann tú é seo bainfear gach síntiús brú reatha láithreach.",
            "2 (apparent temperature ≥ 30 °C)": "2 (teocht mhothaithe ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (teocht mhothaithe ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (teocht mhothaithe ≥ 40 °C)",
            "Active Topic Subscriptions": "Síntiúis ghníomhacha ar thopaicí",
            "Add": "Cuir leis",
            "Address search failed. Please try again.": "Theip ar chuardach seolta. Bain triail eile as.",
            "Adjust schedules and actively protect teams.": "Coigeartaigh sceidil agus cosain foirne go gníomhach.",
            "All clear. Standard precautions are sufficient.": "Tá gach rud socair. Is leor na gnáthréamhchúraimí.",
            "All day": "An lá ar fad",
            "Allow & Start": "Ceadaigh agus tosaigh",
            "Appearance": "Cuma",
            "Apply Heat-V protective measures immediately.": "Cuir bearta cosanta Heat-V i bhfeidhm láithreach.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "Ag innéacs UV 5 nó níos airde, méadaíonn an nochtadh go mór. Úsáid éadaí cosanta, clúdach cinn, spéaclaí gréine agus grianscéithe go seasta.",
            "Auto": "Uathoibríoch",
            "Call 144 now": "Glaoigh ar 144 anois",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Glaoigh ar na seirbhísí éigeandála (144) mura bhfeabhsaíonn an riocht go luath nó má tá comharthaí caillteanais comhfhiosachta ann",
            "Cancel": "Cealaigh",
            "Choose a result": "Roghnaigh toradh",
            "City, Street...": "Cathair, sráid...",
            "Close": "Dún",
            "Cool the body, e.g. with damp cloths or ventilation": "Fuaraigh an corp le héadaí tais, comhbhrúite fuara nó aeráil",
            "Create New Workplace": "Cruthaigh láthair oibre nua",
            "Critical": "Criticiúil",
            "Current Risk": "Riosca reatha",
            "Dark": "Dorcha",
            "Data source: GeoSphere Austria": "Foinse sonraí: GeoSphere Austria",
            "Delete workplace": "Scrios láthair oibre",
            "Development": "Forbairt",
            "Elevated": "Ardaithe",
            "Emergency measures": "Bearta éigeandála",
            "Feels Like": "Mothaítear mar",
            "GeoSphere test URL": "URL tástála GeoSphere",
            "Green": "Glas",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Tinneas cinn, meadhrán, masmas
            Laige, crampaí, mearbhall
            Craiceann te tirim nó craiceann an-allais
            Comhfhios lagaithe
            """,
            "Heat Protection Measures": "Bearta cosanta teasa",
            "Heat Safety at a Glance": "Sábháilteacht teasa go hachomair",
            "Heat protection checklist for businesses": "Seicliosta cosanta teasa do ghnólachtaí",
            "Heat warning level": "Leibhéal rabhaidh teasa",
            "Heat warning scale": "Scála rabhaidh teasa",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Is féidir na hairíonna a bhaineann le teas a bheith san áireamh",
            "High": "Ard",
            "If set, this URL is used instead of the GeoSphere server.": "Má tá sé socraithe, úsáidtear an URL seo in ionad fhreastalaí GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Mura bhfuil gnáth-análú ann, cuir CPR i bhfeidhm láithreach agus faigh cúnamh",
            "If unconscious, place the person in the recovery position": "Má tá an duine gan aithne, cuir sa suíomh téarnaimh é",
            "Increase breaks and shade usage.": "Méadaigh sosanna agus úsáid scátha.",
            "Info": "Eolas",
            "Info & Legal": "Eolas agus dlí",
            "Label (optional)": "Lipéad (roghnach)",
            "Later / Skip": "Níos déanaí / Scipeáil",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Lig don duine ól go mall (uisce, tae, tuaslagáin leictrilítí)",
            "Light": "Éadrom",
            "Live data could not be loaded right now. Please try again later.": "Níorbh fhéidir sonraí beo a luchtú faoi láthair. Bain triail eile as níos déanaí.",
            "Loading live data": "Ag luchtú sonraí beo",
            "Loosen clothing": "Scaoil na héadaí",
            "Maximum values across all workplaces": "Uasluachanna ar fud na n-ionad oibre uile",
            "Mock active": "Mock gníomhach",
            "Mock mode enabled": "Mód mock cumasaithe",
            "Mock mode stays active until the app is restarted.": "Fanann mód mock gníomhach go dtí go n-atosófar an aip.",
            "Monitor consciousness and breathing until emergency services arrive": "Déan monatóireacht ar an gcomhfhios agus ar an análú go dtí go dtiocfaidh na seirbhísí éigeandála agus fan leis an duine",
            "Monitored Workplaces": "Láithreacha oibre faoi fhaire",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Bog nochtadh díreach don ghrian agus obair dhian isteach sa scáth nuair is féidir agus teorannaigh an t-am i ngrian láidir.",
            "No active topic subscriptions": "Níl aon síntiúis ghníomhacha ar thopaicí",
            "No matching address found.": "Níor aimsíodh aon seoladh comhoiriúnach.",
            "No workplaces yet.": "Níl aon láthair oibre ann fós.",
            "Open info": "Oscail eolas",
            "Optional": "Roghnach",
            "Organizational measures": "Bearta eagrúcháin",
            "Peak UV": "Buaic-UV",
            "Personal protective measures": "Bearta cosanta pearsanta",
            "Please enter an address.": "Iontráil seoladh le do thoil.",
            "Possible emergency measures": "Bearta éigeandála féideartha",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Cuir go leor uisce óil ar fáil
            Éadaí oibre éadroma le cosaint UV agus grianscéithe (moltar SPF 50), spéaclaí cosanta UV, tuáillí fuaraithe
            Ag brath ar an réimse oibre: clogad sábháilteachta le cosaint mhuiníl
            """,
            "Quick Glance": "Amharc tapa",
            "Red": "Dearg",
            "Refresh data": "Athnuaigh sonraí",
            "Response plan (STOP principle)": "Plean freagartha (prionsabal STOP)",
            "Search Address": "Cuardaigh seoladh",
            "Search address or place": "Cuardaigh seoladh nó áit",
            "Searching address...": "Ag cuardach seolta...",
            "Settings": "Socruithe",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Cuir scáth ar limistéir oibre agus scíthe le paraisóil (shoghluaiste), pailliúin srl.
            Úsáid bearta teicniúla fuaraithe amhail gaothairí
            Laghdaigh obair atá dian go fisiciúil, m.sh. trí áiseanna ardaithe a úsáid
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Aistrigh uaireanta oibre: sceideal obair throm do na huaireanta maidine níos fuaire
            Cuir sosanna cuí ar fáil chun fuarú
            Déan tascanna troma sa scáth nó i limistéir fhionnuara
            """,
            "Stable": "Seasmhach",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Ó leibhéal rabhaidh teasa 2 (ó 30 °C), ní mór plean freagartha agus bearta éigeandála a chur i bhfeidhm. I measc na mbeart is féidir tá:",
            "Stay informed": "Fan ar an eolas",
            "Stop work and move the affected person to shade or a cool place": "Stop an obair agus bog an duine atá buailte isteach sa scáth nó i seomra fionnuar",
            "System": "Córas",
            "System language": "Teanga an chórais",
            "Technical measures": "Bearta teicniúla",
            "The workplace could not be added.": "Níorbh fhéidir an láthair oibre a chur leis.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Taispeánann an seisiún aip seo leibhéil rabhaidh randamacha anois do gach láthair oibre. Múchfar an mód arís ag an gcéad atosú eile.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Is dócha go bhfuil an limistéar seo lasmuigh den Ostair nó nach n-aithníonn GeoSphere é. Ní féidir é a chur leis.",
            "Today": "Inniu",
            "Topics": "Topaicí",
            "Traffic-light status, UV and workplaces live in one view.": "Stádas soilse tráchta, UV agus láithreacha oibre beo in aon amharc amháin.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Innéacs UV >= 5",
            "UV Protection Measures": "Bearta cosanta UV",
            "Unable to add": "Ní féidir a chur leis",
            "Warnings": "Rabhaidh",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Cabhraímid leat riachtanais dhlíthiúla maidir le rioscaí ó theas agus radaíocht UV nádúrtha in obair lasmuigh a chomhlíonadh. Coinnigh súil ar theocht agus ar an innéacs UV i gcónaí.",
            "Welcome to Hitze-V": "Fáilte go Hitze-V",
            "Workplaces": "Láithreacha oibre",
            "Yellow": "Buí",
            "n/a": "n/b",
        ],
        .mt: [
            "Push notifications": "Notifikazzjonijiet push",
            "Choose whether heat alerts are sent as push notifications and for which worksites.": "Agħżel jekk it-twissijiet tas-sħana għandhomx jintbagħtu bħala notifikazzjonijiet push u għal liema postijiet tax-xogħol.",
            "Enable push notifications": "Attiva n-notifikazzjonijiet push",
            "Worksites for push": "Postijiet tax-xogħol għan-notifikazzjonijiet push",
            "Add a worksite first to control push notifications individually.": "L-ewwel żid post tax-xogħol biex timmaniġġja n-notifikazzjonijiet push individwalment.",
            "No address available": "L-ebda indirizz disponibbli",
            "Turning this off immediately removes all current push subscriptions.": "It-tifi ta' dan ineħħi minnufih l-abbonamenti push kollha attwali.",
            "2 (apparent temperature ≥ 30 °C)": "2 (temperatura perċepita ≥ 30 °C)",
            "3 (apparent temperature ≥ 35 °C)": "3 (temperatura perċepita ≥ 35 °C)",
            "4 (apparent temperature ≥ 40 °C)": "4 (temperatura perċepita ≥ 40 °C)",
            "Active Topic Subscriptions": "Abbonamenti attivi għat-topiċi",
            "Add": "Żid",
            "Address search failed. Please try again.": "It-tfittxija tal-indirizz falliet. Jekk jogħġbok erġa' pprova.",
            "Adjust schedules and actively protect teams.": "Aġġusta l-iskedi u ipproteġi t-timijiet b'mod attiv.",
            "All clear. Standard precautions are sufficient.": "Kollox sew. Il-prekawzjonijiet standard huma biżżejjed.",
            "All day": "Il-ġurnata kollha",
            "Allow & Start": "Ippermetti u ibda",
            "Appearance": "Dehra",
            "Apply Heat-V protective measures immediately.": "Applika minnufih il-miżuri ta' protezzjoni Heat-V.",
            "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.": "B'indiċi UV ta' 5 jew aktar, l-esponiment jiżdied b'mod sinifikanti. Uża b'mod konsistenti ħwejjeġ protettivi, kopertura għar-ras, nuċċalijiet tax-xemx u krema protettiva.",
            "Auto": "Awtomatiku",
            "Call 144 now": "Ċempel 144 issa",
            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness": "Ċempel lis-servizzi ta' emerġenza (144) jekk il-kundizzjoni ma titjiebx dalwaqt jew jekk hemm sinjali ta' telf ta' sensi",
            "Cancel": "Ikkanċella",
            "Choose a result": "Agħżel riżultat",
            "City, Street...": "Belt, triq...",
            "Close": "Agħlaq",
            "Cool the body, e.g. with damp cloths or ventilation": "Kessaħ il-ġisem b'ċraret imxarrbin, kompressi kesħin jew ventilazzjoni",
            "Create New Workplace": "Oħloq post tax-xogħol ġdid",
            "Critical": "Kritiku",
            "Current Risk": "Riskju attwali",
            "Dark": "Skur",
            "Data source: GeoSphere Austria": "Sors tad-data: GeoSphere Austria",
            "Delete workplace": "Ħassar post tax-xogħol",
            "Development": "Żvilupp",
            "Elevated": "Elevat",
            "Emergency measures": "Miżuri ta' emerġenza",
            "Feels Like": "Tħossok bħal",
            "GeoSphere test URL": "URL tat-test ta' GeoSphere",
            "Green": "Aħdar",
            """
            Headaches, dizziness, nausea
            Weakness, cramps, confusion
            Hot, dry skin or very sweaty skin
            Impaired consciousness
            """: """
            Uġigħ ta' ras, sturdament, dardir
            Dgħjufija, bugħawwieġ, konfużjoni
            Ġilda sħuna u niexfa jew ġilda li tgħarraq ħafna
            Kuxjenza mfixkla
            """,
            "Heat Protection Measures": "Miżuri ta' protezzjoni mis-sħana",
            "Heat Safety at a Glance": "Sigurtà mis-sħana f'daqqa t'għajn",
            "Heat protection checklist for businesses": "Lista ta' kontroll għall-protezzjoni mis-sħana għan-negozji",
            "Heat warning level": "Livell ta' twissija tas-sħana",
            "Heat warning scale": "Skala tat-twissija tas-sħana",
            "Heat-V": "Heat-V",
            "Heat-related symptoms can include": "Sintomi relatati mas-sħana jistgħu jinkludu",
            "High": "Għoli",
            "If set, this URL is used instead of the GeoSphere server.": "Jekk ikun issettjat, dan l-URL jintuża minflok is-server ta' GeoSphere.",
            "If there is no normal breathing, start CPR immediately and get help": "Jekk ma hemmx nifs normali, ibda CPR minnufih u ġib l-għajnuna",
            "If unconscious, place the person in the recovery position": "Jekk il-persuna hija mitlufa minn sensiha, poġġiha fil-pożizzjoni ta' rkupru",
            "Increase breaks and shade usage.": "Żid il-waqfiet u l-użu tad-dell.",
            "Info": "Informazzjoni",
            "Info & Legal": "Informazzjoni u legali",
            "Label (optional)": "Tikketta (mhux obbligatorja)",
            "Later / Skip": "Aktar tard / Aqbeż",
            "Let the person drink slowly (water, tea, electrolyte solutions)": "Ħalli lill-persuna tixrob bil-mod (ilma, te, soluzzjonijiet elettrolitiċi)",
            "Light": "Ċar",
            "Live data could not be loaded right now. Please try again later.": "Id-data live ma setgħetx titgħabba bħalissa. Jekk jogħġbok erġa' pprova aktar tard.",
            "Loading live data": "Qed titgħabba d-data live",
            "Loosen clothing": "Ħoll il-ħwejjeġ",
            "Maximum values across all workplaces": "Valuri massimi fl-oqsma kollha tax-xogħol",
            "Mock active": "Mock attiv",
            "Mock mode enabled": "Modalità mock attivata",
            "Mock mode stays active until the app is restarted.": "Il-modalità mock tibqa' attiva sakemm l-app terġa' tinbeda.",
            "Monitor consciousness and breathing until emergency services arrive": "Ikkontrolla l-kuxjenza u n-nifs sakemm jaslu s-servizzi ta' emerġenza u ibqa' mal-persuna",
            "Monitored Workplaces": "Postijiet tax-xogħol monitorjati",
            "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.": "Mexxi l-esponiment dirett għax-xemx u x-xogħol iebes għad-dell kull meta jkun possibbli u illimita l-ħin fix-xemx diretta.",
            "No active topic subscriptions": "M'hemm l-ebda abbonamenti attivi għat-topiċi",
            "No matching address found.": "Ma nstab l-ebda indirizz li jaqbel.",
            "No workplaces yet.": "Għad m'hemm l-ebda post tax-xogħol.",
            "Open info": "Iftaħ l-informazzjoni",
            "Optional": "Mhux obbligatorju",
            "Organizational measures": "Miżuri organizzattivi",
            "Peak UV": "L-ogħla UV",
            "Personal protective measures": "Miżuri ta' protezzjoni personali",
            "Please enter an address.": "Jekk jogħġbok daħħal indirizz.",
            "Possible emergency measures": "Miżuri possibbli ta' emerġenza",
            """
            Provide sufficient drinking water
            Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
            Depending on the work area: safety helmet with neck protection
            """: """
            Ipprovdi biżżejjed ilma għax-xorb
            Ħwejjeġ tax-xogħol ħfief b'protezzjoni UV u krema kontra x-xemx (rakkomandat SPF 50), nuċċalijiet bi protezzjoni UV, xugamani li jkessħu
            Skont iż-żona tax-xogħol: elmu protettiv bi protezzjoni għall-għonq
            """,
            "Quick Glance": "Ħarsa malajr",
            "Red": "Aħmar",
            "Refresh data": "Aġġorna d-data",
            "Response plan (STOP principle)": "Pjan ta' reazzjoni (prinċipju STOP)",
            "Search Address": "Fittex indirizz",
            "Search address or place": "Fittex indirizz jew post",
            "Searching address...": "Qed jitfittex l-indirizz...",
            "Settings": "Settings",
            """
            Shade work and rest areas with parasols, pavilions, etc.
            Technical cooling measures such as fans
            Reduce physically strenuous work, e.g. by using lifting aids
            """: """
            Agħmlu dell fiż-żoni tax-xogħol u tal-mistrieħ b'umbrelel (mobbli), pavaljuni eċċ.
            Użaw miżuri tekniċi ta' tkessiħ bħal fannijiet
            Naqqsu x-xogħol fiżikament iebes, pereżempju billi tużaw għajnuniet għall-irfigħ
            """,
            """
            Shift heavy work to cooler times of day
            Take breaks to cool down
            Carry out heavy tasks in shade or cool areas
            """: """
            Mexxu l-ħinijiet tax-xogħol: ippjanaw ix-xogħol tqil għas-sigħat aktar friski ta' filgħodu
            Ipprovdu waqfiet xierqa biex il-ħaddiema jkessħu
            Wettqu kompiti tqal fid-dell jew f'żoni friski
            """,
            "Stable": "Stabbli",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:": "Mil-livell 2 ta' twissija tas-sħana (minn 30 °C), għandu jiġi implimentat pjan ta' reazzjoni u miżuri ta' emerġenza. Il-miżuri possibbli jinkludu:",
            "Stay informed": "Ibqa' infurmat",
            "Stop work and move the affected person to shade or a cool place": "Waqqaf ix-xogħol u mexxi lill-persuna affettwata fid-dell jew f'kamra friska",
            "System": "Sistema",
            "System language": "Lingwa tas-sistema",
            "Technical measures": "Miżuri tekniċi",
            "The workplace could not be added.": "Il-post tax-xogħol ma setax jiżdied.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart.": "Din is-sessjoni tal-app issa turi livelli ta' twissija każwali għall-postijiet tax-xogħol kollha. Il-modalità terġa' tintefa fil-bidu mill-ġdid li jmiss.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible.": "Din iż-żona probabbilment tinsab barra l-Awstrija jew mhix rikonoxxuta minn GeoSphere. Ma tistax tiżdied.",
            "Today": "Illum",
            "Topics": "Topiċi",
            "Traffic-light status, UV and workplaces live in one view.": "Status tad-dawl tat-traffiku, UV u postijiet tax-xogħol live f'veduta waħda.",
            "UV >= 5": "UV >= 5",
            "UV Index >= 5": "Indiċi UV >= 5",
            "UV Protection Measures": "Miżuri ta' protezzjoni UV",
            "Unable to add": "Ma jistax jiżdied",
            "Warnings": "Twissijiet",
            "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.": "Ngħinuk tikkonforma mar-rekwiżiti legali dwar ir-riskji mis-sħana u r-radjazzjoni UV naturali fix-xogħol barra. Żomm għajnejk fuq it-temperaturi u l-indiċi UV il-ħin kollu.",
            "Welcome to Hitze-V": "Merħba f'Hitze-V",
            "Workplaces": "Postijiet tax-xogħol",
            "Yellow": "Isfar",
            "n/a": "mhux disp.",
        ]
    ]
}
