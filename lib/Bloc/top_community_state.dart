part of 'top_community_bloc.dart';

class TopCommunityState {
  final LoadingState loadingState;
  final String category;
  final List<TopCommunity> communities;
  
  const TopCommunityState({
    @required this.loadingState,
    @required this.category,
    @required this.communities
  });
}
