part of '../../../main.dart';

class ExhibitorTab extends StatelessWidget {
  const ExhibitorTab({super.key, 
    required this.account,
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.boothNameController,
    required this.productController,
    required this.replyController,
    required this.boothName,
    required this.products,
    required this.inquiries,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onSaveBooth,
    required this.onAddProduct,
    required this.onReply,
    required this.onLogout,
  });

  final UserAccount? account;
  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController boothNameController;
  final TextEditingController productController;
  final TextEditingController replyController;
  final String boothName;
  final List<String> products;
  final List<VisitorInquiry> inquiries;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onSaveBooth;
  final VoidCallback onAddProduct;
  final ValueChanged<int> onReply;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentAccount = account;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'Exhibitor',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your booth, services, and visitor enquiries.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 14),
          if (currentAccount == null)
            ExhibitorLoginCard(
              registerMode: registerMode,
              nameController: nameController,
              emailController: emailController,
              onToggleMode: onToggleMode,
              onSubmit: onSubmit,
            )
          else ...[
            ExhibitorHeader(account: currentAccount, onLogout: onLogout),
            ExhibitorBoothCard(
              boothName: boothName,
              controller: boothNameController,
              onSave: onSaveBooth,
            ),
            ExhibitorProductsCard(
              products: products,
              controller: productController,
              onAdd: onAddProduct,
            ),
            ExhibitorInquiryCard(
              inquiries: inquiries,
              replyController: replyController,
              onReply: onReply,
            ),
          ],
        ],
      ),
    );
  }
}

class ExhibitorLoginCard extends StatelessWidget {
  const ExhibitorLoginCard({super.key, 
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
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
              registerMode ? 'Register exhibitor' : 'Exhibitor login',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (registerMode) ...[
              AccountField(
                controller: nameController,
                icon: Icons.badge_outlined,
                label: 'Exhibitor name',
              ),
              const SizedBox(height: 10),
            ],
            AccountField(
              controller: emailController,
              icon: Icons.email_outlined,
              label: 'Business email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: Icon(registerMode ? Icons.person_add : Icons.login),
              label: Text(registerMode ? 'Register / Login' : 'Login'),
            ),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                registerMode
                    ? 'Already registered? Login'
                    : 'New exhibitor? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExhibitorHeader extends StatelessWidget {
  const ExhibitorHeader({super.key, required this.account, required this.onLogout});

  final UserAccount account;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xff0b4238),
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              account.initials,
              style: const TextStyle(
                color: Color(0xff0b4238),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            account.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xffd6eee6)),
          ),
          trailing: IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class ExhibitorBoothCard extends StatelessWidget {
  const ExhibitorBoothCard({super.key, 
    required this.boothName,
    required this.controller,
    required this.onSave,
  });

  final String boothName;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ExhibitorSection(
      icon: Icons.storefront,
      title: 'Manage booth profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(boothName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          AccountField(
            controller: controller,
            icon: Icons.edit_location_alt_outlined,
            label: 'Booth name or profile title',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save booth profile'),
          ),
        ],
      ),
    );
  }
}

class ExhibitorProductsCard extends StatelessWidget {
  const ExhibitorProductsCard({super.key, 
    required this.products,
    required this.controller,
    required this.onAdd,
  });

  final List<String> products;
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ExhibitorSection(
      icon: Icons.inventory_2_outlined,
      title: 'Update products / services',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final product in products)
                Chip(
                  side: BorderSide.none,
                  backgroundColor: const Color(0xffe4f4ee),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(product),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AccountField(
            controller: controller,
            icon: Icons.add_business_outlined,
            label: 'Add product or service',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }
}

class ExhibitorInquiryCard extends StatelessWidget {
  const ExhibitorInquiryCard({super.key, 
    required this.inquiries,
    required this.replyController,
    required this.onReply,
  });

  final List<VisitorInquiry> inquiries;
  final TextEditingController replyController;
  final ValueChanged<int> onReply;

  @override
  Widget build(BuildContext context) {
    return ExhibitorSection(
      icon: Icons.question_answer_outlined,
      title: 'Visitor enquiries',
      child: Column(
        children: [
          for (var i = 0; i < inquiries.length; i++) ...[
            InquiryTile(
              inquiry: inquiries[i],
              replyController: replyController,
              onReply: () => onReply(i),
            ),
            if (i != inquiries.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class InquiryTile extends StatelessWidget {
  const InquiryTile({super.key, 
    required this.inquiry,
    required this.replyController,
    required this.onReply,
  });

  final VisitorInquiry inquiry;
  final TextEditingController replyController;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(
            inquiry.visitor,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(inquiry.message),
        ),
        if (inquiry.response != null)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Text(
              'Response: ${inquiry.response}',
              style: const TextStyle(
                color: Color(0xff0b4238),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...[
          AccountField(
            controller: replyController,
            icon: Icons.reply_outlined,
            label: 'Reply to visitor',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onReply,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Respond'),
            ),
          ),
        ],
      ],
    );
  }
}

class ExhibitorSection extends StatelessWidget {
  const ExhibitorSection({super.key, 
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xffe4f4ee),
                    child: Icon(icon, color: const Color(0xff0b4238)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
