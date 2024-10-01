trigger refreshCustomerTier on Order (after update) {
    Map<Id, Order> oldOrderMap = Trigger.oldMap, newOrderMap = Trigger.newMap;

    for (Id orderId : oldOrderMap.keySet()) {        
        Order oldOrder = oldOrderMap.get(orderId);
        Order newOrder = newOrderMap.get(orderId);

        if (oldOrder.Status == 'Activated') {
            continue;
        }
        if (newOrder.Status == 'Activated') {
            customerTierManager tierManager = new customerTierManager(newOrder.AccountId);
            tierManager.refreshCustomerTier();    
            return;
        }
    }
}