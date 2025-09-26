import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/navigation/screens/main_navigation_screen.dart';
import '../../features/auth/screens/qr_scan_screen.dart';
import '../../features/events/screens/create_event_screen.dart';
import '../../features/events/screens/event_details_screen.dart';
import '../../features/events/screens/event_qr_screen.dart';
import '../../features/media/screens/media_gallery_screen.dart' as media;
import '../../features/media/screens/media_detail_screen.dart';
import '../../features/media/screens/camera_screen.dart';
import '../../features/gallery/screens/device_gallery_screen.dart';
import '../../features/events/screens/events_overview_screen.dart' as events;
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/friends/screens/friends_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter get router => _router;
  
  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WelcomeScreen(),
            ),
          ),
          GoRoute(
            path: '/events',
            name: 'events-overview',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: events.EventsOverviewScreen(),
            ),
          ),
          GoRoute(
            path: '/friends',
            name: 'friends',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FriendsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/qr-scan',
            name: 'qr-scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QRScanScreen(),
            ),
          ),
          GoRoute(
            path: '/create-event',
            name: 'create-event',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CreateEventScreen(),
            ),
          ),
          GoRoute(
            path: '/event/:eventId',
            name: 'event-details',
            pageBuilder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return NoTransitionPage(
                child: EventDetailsScreen(eventId: eventId),
              );
            },
          ),
          GoRoute(
            path: '/event/:eventId/qr',
            name: 'event-qr',
            pageBuilder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return NoTransitionPage(
                child: EventQRScreen(eventId: eventId),
              );
            },
          ),
          GoRoute(
            path: '/event/:eventId/gallery',
            name: 'media-gallery',
            pageBuilder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return NoTransitionPage(
                child: media.MediaGalleryScreen(eventId: eventId),
              );
            },
          ),
          GoRoute(
            path: '/media/:mediaId',
            name: 'media-detail',
            pageBuilder: (context, state) {
              final mediaId = state.pathParameters['mediaId']!;
              return NoTransitionPage(
                child: MediaDetailScreen(mediaId: mediaId),
              );
            },
          ),
          GoRoute(
            path: '/device-gallery',
            name: 'device-gallery',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeviceGalleryScreen(),
            ),
          ),
          GoRoute(
            path: '/gallery',
            name: 'gallery-overview',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: media.EventsOverviewScreen(),
            ),
          ),
          GoRoute(
            path: '/gallery/:eventId',
            name: 'event-gallery',
            pageBuilder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return NoTransitionPage(
                child: media.MediaGalleryScreen(eventId: eventId),
              );
            },
          ),
          GoRoute(
            path: '/welcome',
            name: 'welcome-shell',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WelcomeScreen(),
            ),
          ),
          GoRoute(
            path: '/sign-in',
            name: 'sign-in-shell',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SignInScreen(),
            ),
          ),
          GoRoute(
            path: '/sign-up',
            name: 'sign-up-shell',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SignUpScreen(),
            ),
          ),
          GoRoute(
            path: '/verify-email',
            name: 'verify-email',
            pageBuilder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return NoTransitionPage(
                child: EmailVerificationScreen(email: email),
              );
            },
          ),
        ],
      ),
      // Full-screen routes (without bottom navigation)
      GoRoute(
        path: '/camera/:eventId',
        name: 'camera',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return CameraScreen(eventId: eventId);
        },
      ),
    ],
  );
}