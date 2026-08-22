// lib/features/home/data/sample_data.dart
//
// PLACEHOLDER DATA FOR DEVELOPMENT ONLY.
//
// Every fare and duration below is illustrative. Real figures must come from
// the `transit_routes` and `fare_matrix` tables, sourced from current LTFRB
// issuances with a recorded last_verified_date (see risk R5). Do not present
// these numbers in the defense demonstration as actual fares.
//
// Heritage blurbs are one-line summaries only. Final capsule content comes
// from the curated `heritage_sites` table built on NHCP markers and National
// Museum records (see risk R2).

import 'package:flutter/material.dart';

enum TransitMode {
  jeepney('Jeepney', Icons.airport_shuttle_rounded),
  bus('Bus', Icons.directions_bus_rounded),
  uvExpress('UV Express', Icons.local_taxi_rounded),
  tricycle('Tricycle', Icons.electric_rickshaw_rounded);

  const TransitMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SampleRoute {
  const SampleRoute({
    required this.origin,
    required this.destination,
    required this.mode,
    required this.baseFare,
    required this.minutes,
  });

  final String origin;
  final String destination;
  final TransitMode mode;
  final double baseFare;
  final int minutes;

  String get fareLabel => '₱${baseFare.toStringAsFixed(2)}';
  String get durationLabel => '$minutes min';
}

class SampleHeritageSite {
  const SampleHeritageSite({
    required this.name,
    required this.municipality,
    required this.blurb,
    required this.accent,
  });

  final String name;
  final String municipality;
  final String blurb;
  final Color accent;
}

class SampleData {
  const SampleData._();

  static const routes = <SampleRoute>[
    SampleRoute(
      origin: 'Malolos',
      destination: 'Baliuag',
      mode: TransitMode.jeepney,
      baseFare: 45.00,
      minutes: 55,
    ),
    SampleRoute(
      origin: 'Malolos',
      destination: 'Guiguinto',
      mode: TransitMode.jeepney,
      baseFare: 15.00,
      minutes: 20,
    ),
    SampleRoute(
      origin: 'San Jose del Monte',
      destination: 'Cubao',
      mode: TransitMode.bus,
      baseFare: 75.00,
      minutes: 90,
    ),
    SampleRoute(
      origin: 'Plaridel',
      destination: 'Pulilan',
      mode: TransitMode.jeepney,
      baseFare: 18.00,
      minutes: 25,
    ),
    SampleRoute(
      origin: 'Balagtas',
      destination: 'Bocaue',
      mode: TransitMode.tricycle,
      baseFare: 25.00,
      minutes: 15,
    ),
  ];

  static const heritageSites = <SampleHeritageSite>[
    SampleHeritageSite(
      name: 'Barasoain Church',
      municipality: 'Malolos City',
      blurb: 'Site of the Malolos Congress and the First Philippine Republic.',
      accent: Color(0xFF8C5A2B),
    ),
    SampleHeritageSite(
      name: 'Casa Real Shrine',
      municipality: 'Malolos City',
      blurb: 'Former provincial capitol; housed the Republic\'s printing press.',
      accent: Color(0xFF6B7F4A),
    ),
    SampleHeritageSite(
      name: 'Marcelo H. del Pilar Shrine',
      municipality: 'Bulakan',
      blurb: 'Birthplace of the Propaganda Movement writer and reformist.',
      accent: Color(0xFF3E6B7C),
    ),
    SampleHeritageSite(
      name: 'San Agustin Parish Church',
      municipality: 'Baliuag',
      blurb: 'Colonial-era parish known for its bell tower and retablo.',
      accent: Color(0xFF8A4B52),
    ),
    SampleHeritageSite(
      name: 'Kakarong de Sili Shrine',
      municipality: 'Pandi',
      blurb: 'Commemorates the Katipunan republic established in 1896.',
      accent: Color(0xFF5B5480),
    ),
  ];
}