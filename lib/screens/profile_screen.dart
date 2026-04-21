import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: Provider.of<AuthService>(context, listen: false).getCurrentUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingWidget(isList: false);
          
          final user = snapshot.data!;
          
          return Column(
            children: [
              _buildHeader(user),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.teal.shade700,
                labelColor: Colors.teal.shade700,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                  Tab(text: 'Friends'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedRequests(),
                    _buildSentRequests(),
                    _buildFriendsList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.nickname,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              user.collegeName,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Rating', user.rating.toStringAsFixed(1)),
                _buildStat('Exchanges', user.totalExchanges.toString()),
                _buildStat('Friends', user.friends.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildReceivedRequests() {
    return StreamBuilder<List<FriendRequestModel>>(
      stream: _friendService.getPendingRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(req.senderName),
              subtitle: const Text('wants to connect'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _friendService.acceptFriendRequest(req.id, req.senderId, req.receiverId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _friendService.ignoreFriendRequest(req.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return StreamBuilder<List<FriendRequestModel>>(
      stream: _friendService.getSentRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        
        if (requests.isEmpty) {
          return const Center(child: Text('No sent requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('Waiting for response...'),
              subtitle: Text('Sent to ID: ${req.receiverId}'),
              trailing: const Chip(label: Text('Pending')),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<UserModel>>(
      stream: _friendService.getFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final friends = snapshot.data!;

        if (friends.isEmpty) {
          return const Center(child: Text('No friends added yet'));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person, color: Colors.teal)),
              title: Text(friend.nickname),
              subtitle: Text(friend.collegeName),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                   // Navigate to chat? (Already have chat list)
                },
              ),
            );
          },
        );
      },
    );
  }
}
