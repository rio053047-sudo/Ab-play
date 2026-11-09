import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/customization_store_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class CustomizationStoreScreen extends StatelessWidget {
  const CustomizationStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeVM = Provider.of<CustomizationStoreViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Customization Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Consumer<HomeViewModel>(
                builder: (_, vm, __) => Text(
                  '${vm.coinBalance}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✨ Premium Avatar Decor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Stand out in voice rooms with animated frames, luxury entry effects and custom chat bubbles!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.diamond_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Store Catalog', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: storeVM.catalog.length,
            itemBuilder: (context, index) {
              final item = storeVM.catalog[index];
              return _buildItemCard(context, item, storeVM, homeVM);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, StoreItem item, CustomizationStoreViewModel vm, HomeViewModel homeVM) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isEquipped ? Colors.greenAccent : (item.isOwned ? AppColors.primary : Colors.white12),
          width: item.isEquipped ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (item.isOwned)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: item.isEquipped ? Colors.greenAccent : Colors.white12,
                foregroundColor: item.isEquipped ? Colors.black : Colors.white70,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              onPressed: () => vm.toggleEquip(item.id),
              child: Text(item.isEquipped ? 'Equipped' : 'Equip', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              icon: const Icon(Icons.monetization_on, size: 14),
              label: Text('${item.coinCost}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                final success = vm.purchaseItem(
                  item.id,
                  homeVM.coinBalance,
                  (coins) => homeVM.deductCoins(coins),
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchased & Equipped "${item.title}"!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient Coins! Recharge from Me tab.')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
