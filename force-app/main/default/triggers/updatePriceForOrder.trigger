trigger updatePriceForOrder on OrderItem (after insert, after update, after delete, after undelete) {
    for (OrderItem prod : Trigger.new) {
        Order ord = [SELECT Id, TotalAmount, Discount_Percentage__c, Amount_After_Discount__c 
                    FROM Order WHERE Id = :prod.OrderId LIMIT 1]; 
        ord.Amount_After_Discount__c = ord.TotalAmount-(ord.TotalAmount * (ord.Discount_Percentage__c / 100));
        update ord;
    }
}