trigger applyDiscountOnOrder on Order (before insert) {
    for (Order ord : Trigger.new) {        
        customerTierManager tierManager = new customerTierManager(ord.AccountId);
        tierManager.refreshCustomerTier();    
        ord.Discount_Percentage__c = tierManager.getDiscount();
    }
}