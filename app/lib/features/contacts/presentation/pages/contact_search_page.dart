import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/contact_search_bloc.dart';

/// Màn hình tìm bạn theo số điện thoại — chỉ tìm chính xác (backend chưa
/// hỗ trợ fuzzy search theo tên, xem handlers_users.go).
class ContactSearchPage extends StatefulWidget {
  const ContactSearchPage({super.key});

  @override
  State<ContactSearchPage> createState() => _ContactSearchPageState();
}

class _ContactSearchPageState extends State<ContactSearchPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ContactSearchBloc>().add(ContactSearchEvent.submitted(phone: _phoneController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm bạn')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Nhập số điện thoại' : null,
                onFieldSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              BlocConsumer<ContactSearchBloc, ContactSearchState>(
                listener: (context, state) {
                  if (state.errorMessage != null &&
                      (state.status == ContactSearchStatus.notFound || !state.requestSent)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                  }
                },
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: state.status == ContactSearchStatus.searching ? null : _search,
                        child: state.status == ContactSearchStatus.searching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Tìm kiếm'),
                      ),
                      const SizedBox(height: 24),
                      if (state.status == ContactSearchStatus.found && state.result != null) _buildResult(state),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(ContactSearchState state) {
    final user = state.result!;
    final name = user.displayName.isNotEmpty ? user.displayName : user.phone;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
        title: Text(name),
        subtitle: Text(user.phone),
        trailing: state.requestSent
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton(
                onPressed: state.sending
                    ? null
                    : () => context.read<ContactSearchBloc>().add(const ContactSearchEvent.requestSendRequested()),
                child: state.sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kết bạn'),
              ),
      ),
    );
  }
}
