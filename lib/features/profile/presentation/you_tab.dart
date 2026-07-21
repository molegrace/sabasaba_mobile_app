part of '../../../main.dart';

class YouTab extends StatelessWidget {
  const YouTab({
    required this.account,
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onLogout,
  });

  final UserAccount? account;
  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentAccount = account;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 14),
          if (currentAccount == null)
            AuthCard(
              registerMode: registerMode,
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              onToggleMode: onToggleMode,
              onSubmit: onSubmit,
            )
          else
            AccountCard(account: currentAccount, onLogout: onLogout),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              registerMode ? 'Create account' : 'Login',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (registerMode) ...[
              AccountField(
                controller: nameController,
                icon: Icons.badge_outlined,
                label: 'Full name',
              ),
              const SizedBox(height: 10),
            ],
            AccountField(
              controller: emailController,
              icon: Icons.email_outlined,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            AccountField(
              controller: passwordController,
              icon: Icons.lock_outline,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: Icon(registerMode ? Icons.person_add : Icons.login),
              label: Text(registerMode ? 'Register' : 'Login'),
            ),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                registerMode
                    ? 'Already have an account? Login'
                    : 'New visitor? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, required this.onLogout});

  final UserAccount account;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xff0b4238),
                  child: Text(
                    account.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff40534d)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const InfoTile(
              icon: Icons.bookmark_outline,
              title: 'Saved places',
              subtitle: 'Bookmarked booths and services will appear here.',
            ),
            const InfoTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Updates for services and exhibition events.',
            ),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountField extends StatelessWidget {
  const AccountField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xfff2f5f3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
