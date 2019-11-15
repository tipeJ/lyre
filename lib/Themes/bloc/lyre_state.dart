import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

@immutable
class LyreState extends Equatable {
  final ThemeData themeData;
  final Box settings;
  final bool readOnly;
  final List<String> userNames;
  final Redditor currentUser;

  LyreState({
      @required this.themeData,
      @required this.settings,
      @required this.userNames,
      @required this.currentUser,
      @required this.readOnly
    });
    List<dynamic> get props => [themeData, readOnly, userNames, currentUser, settings];
}
