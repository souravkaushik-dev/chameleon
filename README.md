# 🦎 Chameleon

### Music, reimagined.

Chameleon is a cinematic, modern Flutter music player built for effortless music discovery, seamless playback, playlists, favorites, queue management, and a personalized listening experience.

---

## ✦ Features

### 🎵 Discovery

- ✓ YouTube music search
- ✓ Trending songs
- ✓ Trending artists
- ✓ Suggested songs
- ✓ Real-time music data
- ✓ Pull-to-refresh
- ◦ Advanced search filters
- ◦ Genre discovery
- ◦ Personalized recommendations

### ▶ Playback

- ✓ Play / Pause
- ✓ Previous / Next
- ✓ Seek
- ✓ Queue management
- ✓ Shuffle
- ✓ Repeat
- ✓ Playback position tracking
- ✓ YouTube audio stream resolution
- ◦ Gapless playback
- ◦ Crossfade
- ◦ Sleep timer
- ◦ Playback speed

### 🎧 Now Playing

- ✓ Fullscreen cinematic artwork
- ✓ Immersive player
- ✓ Playback controls
- ✓ Progress slider
- ✓ Favorite control
- ✓ Queue access
- ✓ Song options
- ✓ Animated transitions
- ◦ Lyrics
- ◦ Audio visualizer
- ◦ Audio effects

### 🎶 Mini Player

- ✓ Persistent mini player
- ✓ Artwork
- ✓ Song title
- ✓ Artist
- ✓ Play / Pause
- ✓ Live progress
- ✓ Open full player
- ✓ Smooth animations
- ◦ Swipe gestures

### 🕘 Recently Played

- ✓ Recently played tracking
- ✓ Persistent history
- ✓ Large artwork cards
- ✓ Horizontal scrolling
- ✓ One-tap playback
- ✓ Home screen integration
- ◦ History management
- ◦ Clear history

### ❤️ Favorites

- ✓ Add to favorites
- ✓ Remove from favorites
- ✓ Persistent favorites
- ✓ Library integration
- ◦ Favorite artists
- ◦ Favorite albums

### 📋 Playlists

- ✓ Create playlists
- ✓ Delete playlists
- ✓ Rename playlists
- ✓ Add songs
- ✓ Remove songs
- ✓ Persistent playlists
- ✓ Playlist artwork support
- ◦ Reorder songs
- ◦ Smart playlists
- ◦ Playlist sharing

### 📚 Library

- ✓ Library screen
- ✓ Favorites
- ✓ Playlists
- ✓ Recently played
- ◦ Albums
- ◦ Artists
- ◦ Offline music

### 👤 Artists

- ✓ Artist information
- ✓ Artist names across the app
- ✓ Trending artists
- ◦ Artist profiles
- ◦ Discography
- ◦ Follow artists

### 🏠 Home

- ✓ Cinematic Home screen
- ✓ Recently Played
- ✓ Trending Now
- ✓ Trending Artists
- ✓ Suggested Songs
- ✓ Playlists
- ✓ Favorites
- ✓ Pull-to-refresh
- ✓ Real-time updates
- ✓ Animated content
- ◦ Personalized Home feed

### 🔍 Search

- ✓ Search interface
- ✓ YouTube-powered search
- ✓ Animated results
- ✓ Artwork
- ✓ Artist information
- ✓ One-tap playback
- ◦ Search history
- ◦ Search suggestions
- ◦ Voice search

### 🎨 Design

- ✓ Minimal UI
- ✓ Cinematic visual language
- ✓ Rounded interface
- ✓ Borderless components
- ✓ Artwork-focused layouts
- ✓ Light mode
- ✓ Dark mode
- ✓ Smooth animations
- ✓ Flutter Animate
- ✓ ScreenUtilPlus
- ✓ Floating bottom navigation
- ✓ Floating mini player
- ◦ Dynamic artwork colors
- ◦ Additional themes

### ⚙ Settings

- ✓ Settings screen
- ✓ Appearance
- ✓ Notifications section
- ✓ Audio quality section
- ✓ About section
- ◦ Full theme customization
- ◦ Cache management
- ◦ Data usage controls
- ◦ Advanced audio settings

---

## 🛠 Built With

- **Flutter** — UI & application framework
- **Dart** — Programming language
- **YouTube Explode Dart** — Music discovery & stream resolution
- **just_audio** — Audio playback
- **Advanced Salomon Bottom Bar** — Navigation
- **Flutter ScreenUtil Plus** — Responsive sizing
- **Flutter Animate** — Animations
- **Google Fonts** — Typography
- **Shared Preferences** — Local persistence

---

## 🏗 Architecture

```text
lib/
├── app/
├── core/
├── data/
│   ├── models/
│   ├── services/
│   └── storage/
├── features/
│   ├── home/
│   ├── search/
│   ├── library/
│   ├── player/
│   └── settings/
└── main.dart