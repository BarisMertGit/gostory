# Changelog

## 1.1.0+2 — Unreleased

- Preview requests a location once when needed, with progress and manual map override.
- Location picker follows in-flight GPS and retries while preserving a manually placed pin.
- Camera-only memory creation; gallery selection remains available for profile photos.
- Profile shows own memories without a saved/bookmarked memories section.
- Comment keyboard submission, empty-message guard, progress/success feedback and dated cards.
- Privacy-preserving creation lifecycle events (start/local commit/failure).
- Public/private memory visibility and owner visibility editing.
- Durable upload/delete queue with revision-safe acknowledgement and connection retries.
- Optional Firebase initialization, anonymous authentication, Storage/Firestore rules and App Check.
- Public author profile navigation and validated social links.
- Unique visitor counts, likes and comments; server counter triggers.
- Opt-in FCM reply and nearby-memory notifications.
- Paged cloud discovery, limited profile batches, network image caching and bounded photo/tile caches.
- Provider, widget, contrast and scripted camera-to-profile flow tests.
- GoStory launcher/splash branding, store metadata/legal drafts and CI workflows.

## 1.0.0+1

- Device-local profile, photo/note archive, location selection and map discovery.

Version format: MAJOR.MINOR.PATCH+BUILD. Breaking archive/API changes increase MAJOR;
compatible features increase MINOR; fixes increase PATCH. BUILD always increases
for each uploaded store artifact. Move Unreleased to a dated release only after validation.
