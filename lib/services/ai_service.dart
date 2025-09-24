// lib/services/ai_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '../models/rich_ai_response.dart';
import '../models/game_stats.dart';
import '../models/user.dart';
import '../screens/schedule_screen.dart' as app_event;
import 'firebase_service.dart';

class AIService {
  GenerativeModel? _model;

  Future<void> initialize(String apiKey) async {
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    } else {
      print(
          '--- WARNING: Gemini API Key is empty. AI Service will not work. ---');
    }
  }

  Future<RichAIResponse> getResponse(String userPrompt,
      FirebaseService firebaseService, User? currentUser) async {
    final stopwatch = Stopwatch()..start();

    if (_model == null) {
      return RichAIResponse(
          responseText:
              "AI Service is not initialized. Please check your API key.");
    }

    try {
      final intentJson = await _recognizeIntent(userPrompt);
      final intent = intentJson['intent'];
      final entities = (intentJson['entities'] as Map<String, dynamic>?) ?? {};

      print(
          "--- PERFORMANCE METRIC: AI Intent Recognition took ${stopwatch.elapsedMilliseconds} ms ---");

      RichAIResponse finalResponse;
      switch (intent) {
        case 'get_player_performance':
          finalResponse = await _handlePlayerPerformance(
              entities, firebaseService, currentUser);
          break;
        case 'get_team_summary':
          finalResponse =
              await _handleTeamSummary(entities, firebaseService, currentUser);
          break;
        case 'get_stat_leader':
          finalResponse =
              await _handleStatLeader(entities, firebaseService, currentUser);
          break;
        case 'compare_players':
          finalResponse = await _handlePlayerComparison(
              entities, firebaseService, currentUser);
          break;
        // --- ADD THIS NEW CASE ---
        case 'get_mvp':
          finalResponse =
              await _handleMvp(entities, firebaseService, currentUser);
          break;
        default:
          finalResponse = RichAIResponse(
            responseText:
                "I'm not sure how to answer that. Try asking about a player's performance or the team's last game.",
            suggestedPrompts: [
              "How did the team do last game?",
              "Who was our top scorer?"
            ],
          );
          break;
      }

      stopwatch.stop();
      print(
          "--- PERFORMANCE METRIC: Total AI response pipeline took ${stopwatch.elapsedMilliseconds} ms ---");
      return finalResponse;
    } catch (e) {
      stopwatch.stop();
      print("Error in AI Service: $e");
      return RichAIResponse(
          responseText:
              "Sorry, I had trouble understanding that. Could you try rephrasing?");
    }
  }

  Future<Map<String, dynamic>> _recognizeIntent(String userPrompt) async {
    final prompt = """
    Analyze the user query and classify its intent and extract entities.
    Possible intents are: 'get_player_performance', 'get_team_summary', 'get_stat_leader', 'compare_players', 'get_mvp'.
    Possible entities are: 'player_name', 'player_name_2', 'stat_category' (e.g., 'points', 'rebounds', 'assists').
    For 'compare_players', 'player_name' is the first name mentioned and 'player_name_2' is the second.
    The timeframe is always 'last_game'.
    The term 'MVP' or 'most valuable player' corresponds to the 'get_mvp' intent.
    Respond ONLY with a valid JSON object.

    Query: "$userPrompt"
    
    JSON Response:
  """;

    final response = await _model!.generateContent([Content.text(prompt)]);
    final jsonString =
        response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
    return jsonDecode(jsonString);
  }

  Future<RichAIResponse> _handlePlayerPerformance(Map<String, dynamic> entities,
      FirebaseService firebaseService, User? currentUser) async {
    final playerName = entities['player_name'] as String?;
    if (playerName == null)
      return RichAIResponse(
          responseText: "I couldn't identify a player name in your question.");

    final allPlayers = await firebaseService.getPlayersStream().first;
    User? player = allPlayers.firstWhereOrNull(
        (p) => p.name?.toLowerCase() == playerName.toLowerCase());

    if (player == null)
      return RichAIResponse(
          responseText:
              "I couldn't find a player named '$playerName' on your roster.");

    final playerGames = await firebaseService.getStatsForPlayer(player.userId);
    if (playerGames.isEmpty)
      return RichAIResponse(
          responseText:
              "It looks like '$playerName' has not played in any games with recorded stats yet.");

    final lastGameStats = playerGames.first;
    final eventTitle =
        await firebaseService.getEventTitleById(lastGameStats.eventId);

    final totalGames = playerGames.length;
    final avgPts = playerGames.fold(0.0, (sum, game) => sum + game.totals.pts) /
        totalGames;
    final avgReb = playerGames.fold(0.0, (sum, game) => sum + game.totals.reb) /
        totalGames;
    final avgAst = playerGames.fold(0.0, (sum, game) => sum + game.totals.ast) /
        totalGames;
    final avgTov = playerGames.fold(0.0, (sum, game) => sum + game.totals.tov) /
        totalGames;

    final dataPrompt = """
      You are a helpful basketball coaching assistant.
      The user asking the question is named ${currentUser?.name ?? 'Coach'}.
      Analyze the player's performance in their last game by comparing it to their overall season averages.
      Provide a short, insightful summary in a conversational tone. Address the user, not the player.

      Player Name: ${lastGameStats.playerName}
      Data for the Last Game (${eventTitle ?? 'Unknown Game'}):
      - Points (PTS): ${lastGameStats.totals.pts}
      - Rebounds (REB): ${lastGameStats.totals.reb}
      - Assists (AST): ${lastGameStats.totals.ast}
      - Turnovers (TOV): ${lastGameStats.totals.tov}
      Player's Season Averages ($totalGames games):
      - Points per Game (PPG): ${avgPts.toStringAsFixed(1)}
      - Rebounds per Game (RPG): ${avgReb.toStringAsFixed(1)}
      - Assists per Game (APG): ${avgAst.toStringAsFixed(1)}
      - Turnovers per Game (TPG): ${avgTov.toStringAsFixed(1)}
    """;

    final finalResponse =
        await _model!.generateContent([Content.text(dataPrompt)]);
    final otherPlayer =
        allPlayers.firstWhereOrNull((p) => p.userId != player!.userId);

    return RichAIResponse(
      responseText: finalResponse.text ??
          "I found the stats but couldn't generate a summary.",
      dataSource: eventTitle,
      suggestedPrompts: [
        "How did the team do in that game?",
        if (otherPlayer != null)
          "Compare ${player.name} to ${otherPlayer.name}",
        "Who was the top scorer in that game?",
      ],
    );
  }

  int _calculatePerformanceScore(StatSet stats) {
    return (stats.pts + stats.reb + stats.ast + stats.stl + stats.blk) -
        ((stats.fga - stats.fgm) + (stats.fta - stats.ftm) + stats.tov);
  }

  Future<RichAIResponse> _handleMvp(Map<String, dynamic> entities,
      FirebaseService firebaseService, User? currentUser) async {
    final eventId = await _findLastEventIdWithStats(firebaseService);
    if (eventId == null) {
      return RichAIResponse(
          responseText:
              "I couldn't find any recent games with recorded stats to determine an MVP.");
    }

    final lastGameStats = await firebaseService.getStatsForEvent(eventId);
    if (lastGameStats.isEmpty) {
      return RichAIResponse(
          responseText:
              "I found the last game, but there are no player stats recorded for it.");
    }

    // Calculate the performance score for each player
    lastGameStats.sort((a, b) => _calculatePerformanceScore(b.totals)
        .compareTo(_calculatePerformanceScore(a.totals)));

    final mvp = lastGameStats.first;
    final eventTitle = await firebaseService.getEventTitleById(eventId);

    final responseText =
        "Based on the performance ratings from the last game, the MVP was ${mvp.playerName}. They finished with a performance score of ${_calculatePerformanceScore(mvp.totals).toStringAsFixed(1)}.";

    return RichAIResponse(
      responseText: responseText,
      dataSource: eventTitle,
      suggestedPrompts: [
        "How did ${mvp.playerName} perform overall?",
        "How did the team do in that game?",
      ],
    );
  }

  Future<RichAIResponse> _handleTeamSummary(Map<String, dynamic> entities,
      FirebaseService firebaseService, User? currentUser) async {
    final eventId = await _findLastEventIdWithStats(firebaseService);
    if (eventId == null)
      return RichAIResponse(
          responseText:
              "I couldn't find any recent games with recorded stats to summarize.");

    final allStats = await firebaseService.getStatsForEvent(eventId);
    if (allStats.isEmpty)
      return RichAIResponse(
          responseText: "No player stats were found for the last game.");

    final eventTitle = await firebaseService.getEventTitleById(eventId);
    int totalPts = allStats.fold(0, (sum, s) => sum + s.totals.pts);
    int totalReb = allStats.fold(0, (sum, s) => sum + s.totals.reb);
    int totalAst = allStats.fold(0, (sum, s) => sum + s.totals.ast);
    int totalTov = allStats.fold(0, (sum, s) => sum + s.totals.tov);

    final prompt = """
      You are a basketball coaching assistant. The user is named ${currentUser?.name ?? 'Coach'}.
      Summarize the team's performance based on these totals from their last game.
      
      Game: ${eventTitle ?? 'Last Game'}
      Team Totals:
      Points: $totalPts
      Rebounds: $totalReb
      Assists: $totalAst
      Turnovers: $totalTov
    """;
    final response = await _model!.generateContent([Content.text(prompt)]);

    return RichAIResponse(
      responseText: response.text ?? "Could not generate summary.",
      dataSource: eventTitle,
      suggestedPrompts: [
        "Who was the MVP in that game?",
        "Who had the most turnovers?"
      ],
    );
  }

  Future<RichAIResponse> _handleStatLeader(Map<String, dynamic> entities,
      FirebaseService firebaseService, User? currentUser) async {
    final statCategory = entities['stat_category'] as String?;
    if (statCategory == null)
      return RichAIResponse(
          responseText:
              "Which stat are you interested in? (e.g., points, rebounds)");

    final eventId = await _findLastEventIdWithStats(firebaseService);
    if (eventId == null)
      return RichAIResponse(
          responseText:
              "I couldn't find any recent games with recorded stats.");

    final lastGameStats = await firebaseService.getStatsForEvent(eventId);
    if (lastGameStats.isEmpty)
      return RichAIResponse(
          responseText:
              "I found the last game, but there are no player stats recorded for it.");

    final eventTitle = await firebaseService.getEventTitleById(eventId);

    late PlayerGameStats leader;
    late num topStat;
    String leaderType = "leader";

    switch (statCategory.toLowerCase()) {
      case 'points':
      case 'scorer':
        leader =
            lastGameStats.reduce((a, b) => a.totals.pts > b.totals.pts ? a : b);
        topStat = leader.totals.pts;
        break;
      case 'rebounds':
        leader =
            lastGameStats.reduce((a, b) => a.totals.reb > b.totals.reb ? a : b);
        topStat = leader.totals.reb;
        break;
      case 'assists':
        leader =
            lastGameStats.reduce((a, b) => a.totals.ast > b.totals.ast ? a : b);
        topStat = leader.totals.ast;
        break;
      case 'steals':
        leader =
            lastGameStats.reduce((a, b) => a.totals.stl > b.totals.stl ? a : b);
        topStat = leader.totals.stl;
        break;
      case 'blocks':
        leader =
            lastGameStats.reduce((a, b) => a.totals.blk > b.totals.blk ? a : b);
        topStat = leader.totals.blk;
        break;
      case 'turnovers':
        leader =
            lastGameStats.reduce((a, b) => a.totals.tov > b.totals.tov ? a : b);
        topStat = leader.totals.tov;
        leaderType = "player with the most";

        // --- THIS IS THE FIX ---
        // If the top "leader" for this negative stat has 0, it's a good thing.
        if (topStat == 0) {
          return RichAIResponse(
            responseText:
                "That's great news! In the last game, no players recorded any turnovers.",
            dataSource: eventTitle,
            suggestedPrompts: [
              "How did the team do overall?",
              "Who was the MVP?"
            ],
          );
        }
        break;
      // --- END OF FIX ---

      default:
        return RichAIResponse(
            responseText:
                "I can find the leader for points, rebounds, assists, steals, blocks, or turnovers. Please specify one.");
    }

    return RichAIResponse(
      responseText:
          "In the last game, the $leaderType in ${statCategory.toLowerCase()} was ${leader.playerName} with $topStat.",
      dataSource: eventTitle,
      suggestedPrompts: [
        "How did ${leader.playerName} perform overall?",
        "How did the team do in that game?",
      ],
    );
  }

  Future<RichAIResponse> _handlePlayerComparison(Map<String, dynamic> entities,
      FirebaseService firebaseService, User? currentUser) async {
    final playerName1 = entities['player_name'] as String?;
    final playerName2 = entities['player_name_2'] as String?;
    if (playerName1 == null || playerName2 == null)
      return RichAIResponse(
          responseText: "Please tell me the two players you want to compare.");

    final allPlayers = await firebaseService.getPlayersStream().first;
    User? player1 = allPlayers.firstWhereOrNull(
        (p) => p.name?.toLowerCase() == playerName1.toLowerCase());
    User? player2 = allPlayers.firstWhereOrNull(
        (p) => p.name?.toLowerCase() == playerName2.toLowerCase());

    if (player1 == null)
      return RichAIResponse(
          responseText: "I couldn't find '$playerName1' on your roster.");
    if (player2 == null)
      return RichAIResponse(
          responseText: "I couldn't find '$playerName2' on your roster.");

    final statsFutures = await Future.wait([
      firebaseService.getStatsForPlayer(player1.userId),
      firebaseService.getStatsForPlayer(player2.userId)
    ]);
    final player1Games = statsFutures[0];
    final player2Games = statsFutures[1];

    if (player1Games.isEmpty || player2Games.isEmpty)
      return RichAIResponse(
          responseText:
              "One or both players do not have any recorded stats yet.");

    PlayerGameStats? p1LastCommonGame, p2LastCommonGame;
    String? commonGameEventId;

    for (final game1 in player1Games) {
      final game2 =
          player2Games.firstWhereOrNull((g2) => g2.eventId == game1.eventId);
      if (game2 != null) {
        p1LastCommonGame = game1;
        p2LastCommonGame = game2;
        commonGameEventId = game1.eventId;
        break;
      }
    }

    if (commonGameEventId == null ||
        p1LastCommonGame == null ||
        p2LastCommonGame == null) {
      return RichAIResponse(
          responseText:
              "I couldn't find a recent game where both ${player1.name} and ${player2.name} played together.");
    }

    final p1AvgPts = player1Games.fold(0.0, (s, g) => s + g.totals.pts) /
        player1Games.length;
    final p2AvgPts = player2Games.fold(0.0, (s, g) => s + g.totals.pts) /
        player2Games.length;

    final eventTitle =
        await firebaseService.getEventTitleById(commonGameEventId);

    final prompt = """
      You are a basketball coaching assistant.
      Compare the performances of the two players below from their last game against each other, using their season averages for context.
      Keep the summary to a short, insightful paragraph.

      Game: ${eventTitle ?? 'Last Game'}
      Player 1: ${p1LastCommonGame.playerName} (Avg ${p1AvgPts.toStringAsFixed(1)} PPG)
      Last Game Stats: ${p1LastCommonGame.totals.pts} PTS, ${p1LastCommonGame.totals.reb} REB, ${p1LastCommonGame.totals.ast} AST

      Player 2: ${p2LastCommonGame.playerName} (Avg ${p2AvgPts.toStringAsFixed(1)} PPG)
      Last Game Stats: ${p2LastCommonGame.totals.pts} PTS, ${p2LastCommonGame.totals.reb} REB, ${p2LastCommonGame.totals.ast} AST
    """;

    final finalResponse = await _model!.generateContent([Content.text(prompt)]);
    return RichAIResponse(
      responseText: finalResponse.text ?? "Could not generate comparison.",
      dataSource: eventTitle,
      suggestedPrompts: [
        "How did the team do in that game?",
        "Who else played well?"
      ],
    );
  }

  Future<String?> _findLastEventIdWithStats(
      FirebaseService firebaseService) async {
    final now = DateTime.now();
    final pastEventsSnapshot = await FirebaseFirestore.instance
        .collection('scheduleEvents')
        .where('dateTime', isLessThan: now)
        .orderBy('dateTime', descending: true)
        .limit(10)
        .get();
    for (final doc in pastEventsSnapshot.docs) {
      if (await firebaseService.doesEventHaveStats(doc.id)) {
        return doc.id;
      }
    }
    return null;
  }
}
