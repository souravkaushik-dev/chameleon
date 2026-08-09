# 🦎 Chameleon

<p align="center">

### Music, reimagined.

A cinematic Flutter music player built for discovering, playing, and enjoying music.

<br>

**Coming soon to Google Play Store**

</p>

---

## ✦ About

**Chameleon** is a modern music player focused on a beautiful listening experience.

Discover trending music, search for songs, build playlists, save favorites, revisit recently played tracks, and enjoy music through an immersive cinematic player.

Built with Flutter and designed from the ground up with a minimal, smooth, and artwork-focused interface.

---

## ✦ Features

### 🎵 Discovery

- ✓ YouTube-powered music search
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
- ✓ Audio stream resolution
- ◦ Gapless playback
- ◦ Crossfade
- ◦ Sleep timer
- ◦ Playback speed

### 🎧 Now Playing

- ✓ Fullscreen cinematic player
- ✓ Large artwork
- ✓ Immersive playback controls
- ✓ Progress slider
- ✓ Favorite control
- ✓ Queue access
- ✓ Song options
- ✓ Smooth animations
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
- ✓ Home integration
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
- ✓ Playlist artwork
- ◦ Song reordering
- ◦ Smart playlists
- ◦ Playlist sharing

### 📚 Library

- ✓ Library
- ✓ Favorites
- ✓ Playlists
- ✓ Recently played
- ◦ Albums
- ◦ Artists
- ◦ Offline music

### 👤 Artists

- ✓ Artist information
- ✓ Artist names throughout the app
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

---

## ✦ Design

Chameleon is built around a simple idea:

> **Music should feel immersive, not complicated.**

- ✓ Minimal interface
- ✓ Cinematic artwork
- ✓ Rounded UI
- ✓ Borderless components
- ✓ Light mode
- ✓ Dark mode
- ✓ Smooth animations
- ✓ Artwork-focused layouts
- ✓ Floating navigation
- ✓ Floating mini player
- ✓ Responsive layouts
- ✓ Flutter Animate
- ✓ ScreenUtilPlus
- ◦ Dynamic artwork-based colors
- ◦ Additional themes

---

## ✦ Technology

| Technology | Purpose |
|---|---|
| Flutter | Application framework |
| Dart | Programming language |
| YouTube Explode Dart | Music discovery & stream resolution |
| just_audio | Audio playback |
| Advanced Salomon Bottom Bar | Navigation |
| Flutter ScreenUtil Plus | Responsive UI |
| Flutter Animate | Animations |
| Google Fonts | Typography |
| Shared Preferences | Local persistence |

---

## ✦ Architecture

```text
lib/
│
├── app/
│
├── core/
│   ├── constants/
│   └── theme/
│
├── data/
│   ├── models/
│   ├── services/
│   └── storage/
│
├── features/
│   ├── home/
│   ├── search/
│   ├── library/
│   ├── player/
│   └── settings/
│
└── main.dart