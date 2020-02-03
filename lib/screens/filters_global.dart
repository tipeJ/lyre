import 'package:flutter/material.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';

class GlobalFilters extends StatelessWidget {
  const GlobalFilters({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Filters")
      ),
      body: FutureBuilder<List<String>>(
        future: PostsProvider().getFilteredSubreddits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            final filteredSubreddits = snapshot.data;
            return ListView.builder(
              itemCount: filteredSubreddits.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(filteredSubreddits[i]),
                onTap: () {
                  
                },
              ),
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}