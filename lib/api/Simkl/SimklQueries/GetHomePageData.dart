part of '../SimklQueries.dart';

Future<List<media.Media>> processMediaResponse(Media? data) async {
  return await compute(
      (data) => data?.map((m) => media.Media.fromSimklAnime(m)).toList() ?? [],
      data?.anime);
}

Future<List<media.Media>> processShowsResponse(Media? data) async {
  return await compute(
      (data) => data?.map((m) => media.Media.fromSimklSeries(m)).toList() ?? [],
      data?.show);
}
Future<List<media.Media>> processMovieResponse(Media? data) async {
  return await compute(
          (data) => data?.map((m) => media.Media.fromSimklMovies(m)).toList() ?? [],
      data?.movies);
}

extension on SimklQueries {
  Future<Map<String, List<media.Media>>> _initHomePage() async {
    final list = <String, List<media.Media>>{};

    Future<Media?> fetchOrLoadLocalData(String key, String url,{bool useLocal = true}) async {
      final localData = loadCustomData<String?>(key);
      if (localData != null && localData.isNotEmpty && useLocal == true) {
        return Media.fromJson(jsonDecode(localData));
      } else {
        final data = await executeQuery<Media>(url);
        saveCustomData(key, jsonEncode(data));
        return data;
      }
    }

    final animeList = await fetchOrLoadLocalData(
      'simklUserAnimeList',
      'https://api.simkl.com/sync/all-items/anime/?extended=full',
    );
    final showList = await fetchOrLoadLocalData(
      'simklUserShowList',
      'https://api.simkl.com/sync/all-items/shows/?extended=full',
    );
    final movieList = await fetchOrLoadLocalData(
      'simklUserMovieList',
      'https://api.simkl.com/sync/all-items/movies/?extended=full',
    );

    var activity = await executeQuery<Activity>(
      'https://api.simkl.com/sync/activities',
    );

    if (loadCustomData<String?>('simklUserActivity') == null) {
      saveCustomData('simklUserActivity', jsonEncode(activity));
    }

    var lastActivity = Activity.fromJson(
      jsonDecode(
        loadCustomData<String?>('simklUserActivity') ?? jsonEncode(activity),
      ),
    );

    if (lastActivity.all != activity?.all) {
      var isAnimeRemoved = lastActivity.anime?.removedFromList != activity?.anime?.removedFromList;
      var isShowRemoved = lastActivity.tvShows?.removedFromList != activity?.tvShows?.removedFromList;
      var isMovieRemoved = lastActivity.movies?.removedFromList != activity?.movies?.removedFromList;
      if (lastActivity.anime?.all != activity?.anime?.all && !(isAnimeRemoved)) {
        var updaterAnimeList = await executeQuery<Media>(
          'https://api.simkl.com/sync/all-items/anime/?extended=full&date_from=${lastActivity.anime?.all}',
        );
        if (animeList != null && updaterAnimeList != null) {
          for (var updatedMedia in updaterAnimeList.anime!) {
            final index = animeList.anime?.indexWhere(
              (media) =>
                  media.show?.ids?.simkl == updatedMedia.show?.ids?.simkl,
            );
            if (index != -1 && index != null) {
              animeList.anime?[index] = updatedMedia;
            } else {
              animeList.anime?.add(updatedMedia);
            }
          }
          saveCustomData('simklUserAnimeList', jsonEncode(animeList));
        }
      }else if (isAnimeRemoved){
        final updaterAnimeList = await fetchOrLoadLocalData(
          'simklUserAnimeList',
          'https://api.simkl.com/sync/all-items/anime/?extended=full',
          useLocal: false
        );
        animeList?.anime = updaterAnimeList?.anime;
        saveCustomData('simklUserAnimeList', jsonEncode(updaterAnimeList));
      }
      if (lastActivity.tvShows?.all != activity?.tvShows?.all && !isShowRemoved) {
        var updaterShowList = await executeQuery<Media>(
          'https://api.simkl.com/sync/all-items/shows/?extended=full&date_from=${lastActivity.tvShows?.all}',
        );
        if (showList != null && updaterShowList != null) {
          for (var updatedMedia in updaterShowList.show!) {
            final index = showList.show?.indexWhere(
              (media) =>
                  media.show?.ids?.simkl == updatedMedia.show?.ids?.simkl,
            );
            if (index != -1 && index != null) {
              showList.show?[index] = updatedMedia;
            } else {
              showList.show?.add(updatedMedia);
            }
          }
          saveCustomData('simklUserShowList', jsonEncode(showList));
        }
      }else if (isShowRemoved){
        final updaterShowList = await fetchOrLoadLocalData(
          'simklUserShowList',
          'https://api.simkl.com/sync/all-items/shows/?extended=full',
          useLocal: false
        );
        showList?.show = updaterShowList?.show;
        saveCustomData('simklUserShowList', jsonEncode(updaterShowList));
      }
      if (lastActivity.movies?.all != activity?.movies?.all && !isMovieRemoved) {
        var updaterMovieList = await executeQuery<Media>(
          'https://api.simkl.com/sync/all-items/movies/?extended=full&date_from=${lastActivity.movies?.all}',
        );
        if (movieList != null && updaterMovieList != null) {
          for (var updatedMedia in updaterMovieList.movies!) {
            final index = movieList.movies?.indexWhere(
                  (media) =>
              media.movie?.ids?.simkl == updatedMedia.movie?.ids?.simkl,
            );
            if (index != -1 && index != null) {
              movieList.movies?[index] = updatedMedia;
            } else {
              movieList.movies?.add(updatedMedia);
            }
          }
          saveCustomData('simklUserMovieList', jsonEncode(movieList));
        }
      } else if (isMovieRemoved){
        final updaterMovieList = await fetchOrLoadLocalData(
          'simklUserMovieList',
          'https://api.simkl.com/sync/all-items/movies/?extended=full',
          useLocal: false
        );
        movieList?.movies = updaterMovieList?.movies;
        saveCustomData('simklUserMovieList', jsonEncode(updaterMovieList));
      }
      saveCustomData('simklUserActivity', jsonEncode(activity));
    }

    final responses = await Future.wait([
      processMediaResponse(animeList),
      processShowsResponse(showList),
      processMovieResponse(movieList),
    ]);

    Map<String, List<media.Media>> groupByStatus(List<media.Media> mediaList) {
      return groupBy(mediaList, (m) => m.userStatus ?? 'other');
    }

    final groupedAnimeList = groupByStatus(responses[0]);
    final groupedShowList = groupByStatus(responses[1]);
    final groupedMovieList = groupByStatus(responses[2]);
    list['watchingAnime'] = groupedAnimeList['CURRENT'] ?? [];
    list['droppedAnime'] = groupedAnimeList['DROPPED'] ?? [];
    list['plannedAnime'] = groupedAnimeList['PLANNING'] ?? [];
    list['onHoldAnime'] = groupedAnimeList['HOLD'] ?? [];
    list['watchingShows'] = groupedShowList['CURRENT'] ?? [];
    list['droppedShows'] = groupedShowList['DROPPED'] ?? [];
    list['plannedShows'] = groupedShowList['PLANNING'] ?? [];
    list['onHoldShows'] = groupedShowList['HOLS'] ?? [];
    list['watchingMovies'] = groupedMovieList['CURRENT'] ?? [];
    list['droppedMovies'] = groupedMovieList['DROPPED'] ?? [];
    list['plannedMovies'] = groupedMovieList['PLANNING'] ?? [];
    list['onHoldMovies'] = groupedMovieList['HOLD'] ?? [];
    return list;
  }
}
