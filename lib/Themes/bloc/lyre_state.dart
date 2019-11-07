import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

@immutable
class LyreState extends Equatable {
  final ThemeData themeData;
  final Box settings;

  LyreState({
      @required this.themeData,
      @required this.settings,
    });
    List<dynamic> get props => [themeData];
}
