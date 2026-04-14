from pathlib import Path

path = Path('/workspaces/take3/preview/index.html')
current = path.read_text(encoding='utf-8')
idx = current.index('</head>')
css_part = current[:idx + len('</head>')]

body = """<body>
  <div class="page-header">
    <span class="badge">Maquette Interactive</span>
    <h1>Take30</h1>
    <p>Naviguez entre les 12 écrans de l'application</p>
  </div>
  <nav class="nav-bar">
    <button class="nav-btn active" onclick="go('splash')">Splash</button>
    <button class="nav-btn" onclick="go('onboarding')">Onboarding</button>
    <button class="nav-btn" onclick="go('home')">Accueil</button>
    <button class="nav-btn" onclick="go('explorer')">Explorer</button>
    <button class="nav-btn" onclick="go('record')">Enregistrer</button>
    <button class="nav-btn" onclick="go('preview')">Prévisualisation</button>
    <button class="nav-btn" onclick="go('battle')">Battle</button>
    <button class="nav-btn" onclick="go('leaderboard')">Classement</button>
    <button class="nav-btn" onclick="go('profile')">Profil</button>
    <button class="nav-btn" onclick="go('badges')">Badges</button>
    <button class="nav-btn" onclick="go('notifications')">Notifications</button>
    <button class="nav-btn" onclick="go('challenge')">Défi du jour</button>
  </nav>

  <div class="phone-wrap">
    <div class="iphone">
      <div class="notch"></div>
      <div class="screen-area">
        <div class="status-bar"><span>9:41</span><span>📶 🔋</span></div>

        <div class="screen active" id="splash">
          <div class="splash-screen">
            <div class="splash-logo">Take30</div>
            <p class="splash-sub">Créer. Partager. Briller.</p>
            <button class="btn btn-yellow" style="margin-top:32px" onclick="go('onboarding')">Commencer</button>
          </div>
        </div>

        <div class="screen" id="onboarding">
          <div class="onboard-visual">🎬</div>
          <div class="screen-body" style="text-align:center; padding-top: 8px;">
            <h2 style="font-size:22px; font-weight:800; margin-bottom:8px;">Ton film en 30 min</h2>
            <p style="color:var(--muted); font-size:14px; line-height:1.6; margin-bottom:10px;">Enregistre, monte et publie des scènes créatives en un temps record, depuis ton téléphone.</p>
            <div class="onboard-dots">
              <span class="dot active"></span><span class="dot"></span><span class="dot"></span>
            </div>
            <button class="btn btn-yellow btn-block" onclick="go('home')">Suivant →</button>
          </div>
        </div>

        <div class="screen" id="home">
          <div class="screen-header">
            <h2>Accueil</h2>
            <button class="icon-btn" onclick="go('notifications')">🔔</button>
          </div>
          <div class="screen-body" style="padding-bottom:88px;">
            <div class="s-card" style="background:linear-gradient(135deg, rgba(255,184,0,0.20), rgba(0,212,255,0.14)); border-color:rgba(255,255,255,0.12);">
              <p style="font-size:12px; color:rgba(255,255,255,0.78); margin-bottom:6px;">Bonjour Stef</p>
              <h3 style="font-size:20px; margin-bottom:10px;">Prêt à créer un nouveau Take ?</h3>
              <button class="btn btn-yellow" onclick="go('record')">🎬 Nouveau Take</button>
            </div>
            <div class="s-card">
              <h3>Fil d'activité</h3>
              <div class="feed-item">
                <div class="avatar">M</div>
                <div class="feed-meta">
                  <div class="name">Marie L.</div>
                  <div class="desc">a publié « Cuisine de nuit » dans Lifestyle</div>
                  <div class="time">Il y a 8 min</div>
                </div>
              </div>
              <div class="feed-item">
                <div class="avatar" style="background:linear-gradient(135deg, #6C5CE7, #00D4FF);">T</div>
                <div class="feed-meta">
                  <div class="name">Thomas K.</div>
                  <div class="desc">a remporté une battle avec 58% des votes</div>
                  <div class="time">Il y a 22 min</div>
                </div>
              </div>
              <div class="feed-item">
                <div class="avatar" style="background:linear-gradient(135deg, #FFB800, #FF4D4F);">S</div>
                <div class="feed-meta">
                  <div class="name">Sara N.</div>
                  <div class="desc">a relevé le défi du jour « Lumière naturelle »</div>
                  <div class="time">Il y a 1 h</div>
                </div>
              </div>
            </div>
          </div>
          <div class="tab-bar">
            <button class="tab-item active" onclick="go('home')"><span class="tab-icon">🏠</span><span>Accueil</span></button>
            <button class="tab-item" onclick="go('explorer')"><span class="tab-icon">🧭</span><span>Explorer</span></button>
            <button class="tab-item rec-btn" onclick="go('record')"><span class="tab-icon">⏺</span><span>Record</span></button>
            <button class="tab-item" onclick="go('battle')"><span class="tab-icon">⚔️</span><span>Battle</span></button>
            <button class="tab-item" onclick="go('profile')"><span class="tab-icon">👤</span><span>Profil</span></button>
          </div>
        </div>

        <div class="screen" id="explorer">
          <div class="screen-header">
            <h2>Explorer</h2>
            <button class="icon-btn">🔍</button>
          </div>
          <div class="screen-body" style="padding-bottom:88px;">
            <div class="tag-row" style="margin-bottom:12px;">
              <span class="pill pill-yellow">Tout</span>
              <span class="pill pill-cyan">Portrait</span>
              <span class="pill pill-purple">Lifestyle</span>
              <span class="pill pill-green">Nature</span>
            </div>
            <div class="s-card" onclick="go('scene-detail')" style="cursor:pointer;">
              <div class="preview-video" style="height:120px; margin-bottom:10px;">🌃</div>
              <h3>Cuisine de nuit</h3>
              <p>Une scène urbaine et intime à découvrir. Appuyer pour voir les détails.</p>
            </div>
            <div class="s-card">
              <div class="preview-video" style="height:120px; margin-bottom:10px;">📸</div>
              <h3>Portrait créatif</h3>
              <p>Jeu de lumière, plans serrés et ambiance studio.</p>
            </div>
            <div class="s-card">
              <div class="preview-video" style="height:120px; margin-bottom:10px;">🎥</div>
              <h3>Mini reportage</h3>
              <p>Une narration simple et percutante tournée en 25 minutes.</p>
            </div>
          </div>
          <div class="tab-bar">
            <button class="tab-item" onclick="go('home')"><span class="tab-icon">🏠</span><span>Accueil</span></button>
            <button class="tab-item active" onclick="go('explorer')"><span class="tab-icon">🧭</span><span>Explorer</span></button>
            <button class="tab-item rec-btn" onclick="go('record')"><span class="tab-icon">⏺</span><span>Record</span></button>
            <button class="tab-item" onclick="go('battle')"><span class="tab-icon">⚔️</span><span>Battle</span></button>
            <button class="tab-item" onclick="go('profile')"><span class="tab-icon">👤</span><span>Profil</span></button>
          </div>
        </div>

        <div class="screen" id="record">
          <div class="screen-header">
            <h2>Enregistrer</h2>
            <button class="icon-btn" onclick="go('home')">✕</button>
          </div>
          <div class="screen-body" style="text-align:center; padding-bottom:88px;">
            <div class="timer-wrap">
              <div class="timer-circle recording">
                <div class="time">24:37</div>
                <div class="label">En cours</div>
              </div>
            </div>
            <div style="display:flex; justify-content:center; gap:16px; margin:10px 0 18px;">
              <button class="icon-btn" style="width:52px; height:52px;">⏸</button>
              <button class="icon-btn" style="width:64px; height:64px; background:rgba(255,77,79,0.18); border-color:rgba(255,77,79,0.5); box-shadow:0 0 22px rgba(255,77,79,0.35);">⏺</button>
              <button class="icon-btn" style="width:52px; height:52px;" onclick="go('preview')">⏹</button>
            </div>
            <div class="s-card" style="text-align:left;">
              <div style="display:flex; align-items:center; justify-content:space-between; gap:8px;">
                <h3>Scène 3 / 5</h3>
                <span class="pill pill-red">● LIVE</span>
              </div>
              <div class="progress-bar"><div class="fill" style="width:60%; background:linear-gradient(90deg, var(--red), var(--yellow));"></div></div>
              <p>Progression globale du tournage.</p>
            </div>
          </div>
          <div class="tab-bar">
            <button class="tab-item" onclick="go('home')"><span class="tab-icon">🏠</span><span>Accueil</span></button>
            <button class="tab-item" onclick="go('explorer')"><span class="tab-icon">🧭</span><span>Explorer</span></button>
            <button class="tab-item rec-btn active" onclick="go('record')"><span class="tab-icon">⏺</span><span>Record</span></button>
            <button class="tab-item" onclick="go('battle')"><span class="tab-icon">⚔️</span><span>Battle</span></button>
            <button class="tab-item" onclick="go('profile')"><span class="tab-icon">👤</span><span>Profil</span></button>
          </div>
        </div>

        <div class="screen" id="preview">
          <div class="screen-header">
            <h2>Prévisualisation</h2>
            <button class="icon-btn" onclick="go('record')">←</button>
          </div>
          <div class="screen-body">
            <div class="preview-video">▶️</div>
            <h3 style="font-size:18px; margin-bottom:6px;">Mon Take créatif</h3>
            <div class="tag-row">
              <span class="pill pill-yellow">Lifestyle</span>
              <span class="pill pill-cyan">30 min</span>
              <span class="pill pill-purple">Montage auto</span>
            </div>
            <div class="s-card">
              <h3>Description</h3>
              <p>Une capsule rapide tournée ce soir, avec une ambiance chaleureuse et un montage dynamique.</p>
            </div>
            <div style="display:flex; gap:10px;">
              <button class="btn btn-outline" style="flex:1;">Modifier</button>
              <button class="btn btn-yellow" style="flex:1;">Publier</button>
            </div>
          </div>
        </div>

        <div class="screen" id="battle">
          <div class="screen-header">
            <h2>Battle</h2>
            <span class="pill pill-red">● EN DIRECT</span>
          </div>
          <div class="screen-body" style="padding-bottom:88px;">
            <div class="s-card" style="text-align:center;">
              <h3>Battle #42</h3>
              <p>Duel du soir • thème « Mouvement »</p>
              <div class="countdown-grid">
                <div class="cd-box"><strong>02</strong><span>h</span></div>
                <div class="cd-box"><strong>15</strong><span>m</span></div>
                <div class="cd-box"><strong>33</strong><span>s</span></div>
              </div>
              <p><strong style="color:var(--white);">126 participants</strong></p>
            </div>
            <div class="battle-vs">
              <div class="battle-side voted">
                <div class="avatar" style="margin:0 auto 8px;">M</div>
                <div style="font-weight:700;">Marie L.</div>
                <div class="score">58%</div>
                <p>voté</p>
              </div>
              <div class="battle-side">
                <div class="avatar" style="margin:0 auto 8px; background:linear-gradient(135deg,#6C5CE7,#00D4FF);">T</div>
                <div style="font-weight:700;">Thomas K.</div>
                <div class="score">42%</div>
                <p>voté</p>
              </div>
            </div>
          </div>
          <div class="tab-bar">
            <button class="tab-item" onclick="go('home')"><span class="tab-icon">🏠</span><span>Accueil</span></button>
            <button class="tab-item" onclick="go('explorer')"><span class="tab-icon">🧭</span><span>Explorer</span></button>
            <button class="tab-item rec-btn" onclick="go('record')"><span class="tab-icon">⏺</span><span>Record</span></button>
            <button class="tab-item active" onclick="go('battle')"><span class="tab-icon">⚔️</span><span>Battle</span></button>
            <button class="tab-item" onclick="go('profile')"><span class="tab-icon">👤</span><span>Profil</span></button>
          </div>
        </div>

        <div class="screen" id="leaderboard">
          <div class="screen-header">
            <h2>Classement</h2>
            <button class="icon-btn">📊</button>
          </div>
          <div class="screen-body">
            <div class="tag-row" style="margin-bottom:12px;">
              <span class="pill pill-yellow">Semaine</span>
              <span class="pill pill-cyan">Mois</span>
              <span class="pill pill-purple">All-time</span>
            </div>
            <div class="s-card">
              <div class="lb-row">
                <div class="lb-rank">🥇</div>
                <div class="lb-info"><div class="name">Marie L.</div><div class="pts">2450pts</div></div>
                <div class="lb-score">2450</div>
              </div>
              <div class="lb-row">
                <div class="lb-rank">🥈</div>
                <div class="lb-info"><div class="name">Thomas K.</div><div class="pts">2180pts</div></div>
                <div class="lb-score">2180</div>
              </div>
              <div class="lb-row">
                <div class="lb-rank">🥉</div>
                <div class="lb-info"><div class="name">Sara N.</div><div class="pts">1920pts</div></div>
                <div class="lb-score">1920</div>
              </div>
              <div class="lb-row" style="background:rgba(255,184,0,0.08); border-radius:12px; padding:12px 10px; margin-top:8px; border-bottom:none;">
                <div class="lb-rank">7</div>
                <div class="lb-info"><div class="name">Stef (toi)</div><div class="pts">1340pts</div></div>
                <div class="lb-score">1340</div>
              </div>
            </div>
          </div>
        </div>

        <div class="screen" id="profile">
          <div class="screen-header">
            <h2>Profil</h2>
            <button class="icon-btn">⚙️</button>
          </div>
          <div class="screen-body" style="text-align:center; padding-bottom:88px;">
            <div class="avatar avatar-lg" style="margin: 0 auto 10px;">S</div>
            <h3 style="font-size:20px; margin-bottom:4px;">Stef</h3>
            <p style="color:var(--muted); margin-bottom:14px;">@stef25 • Jan 2025</p>
            <div class="stat-grid" style="margin-bottom:10px;">
              <div class="stat-box"><strong>5</strong><span>streak</span></div>
              <div class="stat-box"><strong>12</strong><span>takes</span></div>
              <div class="stat-box"><strong>87%</strong><span>score</span></div>
              <div class="stat-box"><strong>Inter</strong><span>niveau</span></div>
            </div>
            <div class="s-card" style="text-align:left;">
              <h3>Prochain badge</h3>
              <p>Maître du rythme</p>
              <div class="progress-bar"><div class="fill" style="width:70%; background:linear-gradient(90deg, var(--cyan), var(--purple));"></div></div>
            </div>
            <div style="display:flex; gap:10px;">
              <button class="btn btn-outline" style="flex:1;" onclick="go('badges')">Badges</button>
              <button class="btn btn-outline" style="flex:1;" onclick="go('leaderboard')">Classement</button>
            </div>
          </div>
          <div class="tab-bar">
            <button class="tab-item" onclick="go('home')"><span class="tab-icon">🏠</span><span>Accueil</span></button>
            <button class="tab-item" onclick="go('explorer')"><span class="tab-icon">🧭</span><span>Explorer</span></button>
            <button class="tab-item rec-btn" onclick="go('record')"><span class="tab-icon">⏺</span><span>Record</span></button>
            <button class="tab-item" onclick="go('battle')"><span class="tab-icon">⚔️</span><span>Battle</span></button>
            <button class="tab-item active" onclick="go('profile')"><span class="tab-icon">👤</span><span>Profil</span></button>
          </div>
        </div>

        <div class="screen" id="badges">
          <div class="screen-header">
            <h2>Badges & Stats</h2>
            <button class="icon-btn" onclick="go('profile')">←</button>
          </div>
          <div class="screen-body">
            <div class="stat-grid" style="grid-template-columns:1fr 1fr; margin-bottom:10px;">
              <div class="stat-box"><strong>🎬</strong><span>Premier</span></div>
              <div class="stat-box"><strong>🔥</strong><span>Streak x5</span></div>
              <div class="stat-box"><strong>⚔️</strong><span>Duelliste active</span></div>
              <div class="stat-box"><strong>🏆</strong><span>Champion</span></div>
              <div class="stat-box"><strong>🎨</strong><span>Cinéaste</span></div>
              <div class="stat-box" style="opacity:0.4;"><strong>💎</strong><span>Diamant</span></div>
            </div>
            <div class="s-card">
              <h3>Takes</h3>
              <p>4/7 pour débloquer la prochaine récompense</p>
              <div class="progress-bar"><div class="fill" style="width:57%; background:var(--yellow);"></div></div>
            </div>
            <div class="s-card">
              <h3>Temps</h3>
              <p>5h42 de création cumulée</p>
              <div class="progress-bar"><div class="fill" style="width:68%; background:var(--cyan);"></div></div>
            </div>
            <div class="s-card">
              <h3>Battles</h3>
              <p>8/12 affrontements complétés</p>
              <div class="progress-bar"><div class="fill" style="width:66%; background:var(--purple);"></div></div>
            </div>
          </div>
        </div>

        <div class="screen" id="notifications">
          <div class="screen-header">
            <h2>Notifications</h2>
            <button class="icon-btn" onclick="go('home')">←</button>
          </div>
          <div class="screen-body">
            <div class="notif-item">
              <span class="notif-dot"></span>
              <div class="notif-content">
                <div class="title">Battle terminée</div>
                <div class="body">Ton duel est clos. Consulte les résultats maintenant.</div>
                <div class="when">Il y a 5 min</div>
              </div>
            </div>
            <div class="notif-item">
              <span class="notif-dot"></span>
              <div class="notif-content">
                <div class="title">Streak x5</div>
                <div class="body">Bravo, tu as créé pendant 5 jours consécutifs.</div>
                <div class="when">Il y a 20 min</div>
              </div>
            </div>
            <div class="notif-item">
              <span class="notif-dot read"></span>
              <div class="notif-content">
                <div class="title">Commentaire</div>
                <div class="body">Marie L. a commenté ton dernier Take.</div>
                <div class="when">Hier</div>
              </div>
            </div>
            <div class="notif-item">
              <span class="notif-dot read"></span>
              <div class="notif-content">
                <div class="title">Nouvelle battle</div>
                <div class="body">Un nouveau thème est disponible pour ce soir.</div>
                <div class="when">Hier</div>
              </div>
            </div>
          </div>
        </div>

        <div class="screen" id="challenge">
          <div class="screen-header">
            <h2>Défi du jour</h2>
            <button class="icon-btn" onclick="go('home')">←</button>
          </div>
          <div class="screen-body" style="text-align:center;">
            <div style="font-size:52px; margin:8px 0;">🎯</div>
            <h3 style="font-size:22px; margin-bottom:6px;">Lumière naturelle</h3>
            <p style="color:var(--muted); margin-bottom:12px;">Capte une ambiance authentique en exploitant uniquement la lumière du jour.</p>
            <div class="s-card">
              <h3>Temps restant</h3>
              <div class="countdown-grid" style="margin-top:10px;">
                <div class="cd-box"><strong>08</strong><span>h</span></div>
                <div class="cd-box"><strong>42</strong><span>m</span></div>
                <div class="cd-box"><strong>15</strong><span>s</span></div>
              </div>
            </div>
            <div class="s-card">
              <h3>Récompenses</h3>
              <div class="tag-row" style="justify-content:center; margin-top:8px;">
                <span class="pill pill-yellow">+150 XP</span>
                <span class="pill pill-cyan">Badge exclusif</span>
                <span class="pill pill-purple">Top classement</span>
              </div>
            </div>
            <button class="btn btn-yellow btn-block" onclick="go('record')">🎬 Relever le défi</button>
          </div>
        </div>

        <div class="screen" id="scene-detail">
          <div class="screen-header">
            <h2>Détail scène</h2>
            <button class="icon-btn" onclick="go('explorer')">←</button>
          </div>
          <div class="screen-body">
            <div class="preview-video">🎬</div>
            <h3 style="font-size:18px; margin-bottom:4px;">Cuisine de nuit</h3>
            <p style="color:var(--muted); margin-bottom:8px;">par Marie L. • Lifestyle • 25 min</p>
            <div class="tag-row">
              <span class="pill pill-yellow">Cinématique</span>
              <span class="pill pill-cyan">Intérieur</span>
              <span class="pill pill-purple">Tendance</span>
            </div>
            <div class="stat-grid" style="margin:10px 0;">
              <div class="stat-box"><strong>4.8⭐</strong><span>note</span></div>
              <div class="stat-box"><strong>128👁️</strong><span>vues</span></div>
              <div class="stat-box"><strong>34💬</strong><span>commentaires</span></div>
              <div class="stat-box"><strong>56❤️</strong><span>likes</span></div>
            </div>
            <div class="s-card">
              <h3>Description</h3>
              <p>Une exploration chaleureuse des textures, du rythme et des petits gestes qui font vivre une cuisine de nuit.</p>
            </div>
            <div style="display:flex; gap:10px;">
              <button class="btn btn-outline" style="flex:1;">Liker</button>
              <button class="btn btn-cyan" style="flex:1;">Commenter</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
    function go(id) {
      document.querySelectorAll('.screen').forEach(function(s) { s.classList.remove('active'); });
      var target = document.getElementById(id);
      if (target) target.classList.add('active');
      document.querySelectorAll('.nav-btn').forEach(function(b) { b.classList.remove('active'); });
      document.querySelectorAll('.nav-btn').forEach(function(b) {
        if (b.getAttribute('onclick') === "go('" + id + "')") b.classList.add('active');
      });
      var tabMap = { home: 0, explorer: 1, record: 2, battle: 3, profile: 4 };
      document.querySelectorAll('.tab-bar').forEach(function(bar) {
        bar.querySelectorAll('.tab-item').forEach(function(t, i) { t.classList.toggle('active', i === tabMap[id]); });
      });
      document.querySelector('.phone-wrap').scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  </script>
</body>
</html>"""

path.write_text(css_part + '\n' + body + '\n', encoding='utf-8')
print('rewrite complete')
