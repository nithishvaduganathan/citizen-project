/// API endpoint constants
class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String adminLogin = '/auth/admin/login';
  static const String firebaseAuth = '/auth/firebase';
  
  // Users
  static const String currentUser = '/users/me';
  static String userByUsername(String username) => '/users/$username';
  
  // Complaints
  static const String complaints = '/complaints';
  static const String nearbyComplaints = '/complaints/nearby';
  static const String myComplaints = '/complaints/my';
  static const String complaintStats = '/complaints/stats';
  static String complaint(String id) => '/complaints/$id';
  static String complaintStatus(String id) => '/complaints/$id/status';
  static String complaintUpvote(String id) => '/complaints/$id/upvote';
  static String complaintComments(String id) => '/complaints/$id/comments';
  
  // Chat
  static const String chatSessions = '/chat/sessions';
  static String chatSession(String id) => '/chat/sessions/$id';
  static String chatMessages(String sessionId) => '/chat/sessions/$sessionId/messages';
  static const String chatLanguages = '/chat/languages';
  
  // Community
  static const String posts = '/community/posts';
  static const String feed = '/community/feed';
  static String post(String id) => '/community/posts/$id';
  static String postLike(String id) => '/community/posts/$id/like';
  static String postVote(String postId, String optionId) => '/community/posts/$postId/vote/$optionId';
  static String postComments(String id) => '/community/posts/$id/comments';
  static String commentLike(String id) => '/community/comments/$id/like';
  static String followUser(String id) => '/community/users/$id/follow';
  static String unfollowUser(String id) => '/community/users/$id/unfollow';
  static String followers(String id) => '/community/users/$id/followers';
  static String following(String id) => '/community/users/$id/following';
  
  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminToggleActive(String id) => '/admin/users/$id/toggle-active';
  static const String pendingAuthorities = '/admin/authorities/pending';
  static String verifyAuthority(String id) => '/admin/authorities/$id/verify';
  static const String complaintHeatmap = '/admin/complaints/heatmap';
  static String authorityComplaints(String type) => '/admin/complaints/by-authority/$type';
  static String hidePost(String id) => '/admin/posts/$id/hide';
  static String hideComplaint(String id) => '/admin/complaints/$id/hide';
  
  ApiEndpoints._();
}
