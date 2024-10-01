@isTest public class customerTierManagerTest {
    @isTest static void testGetBronzeAccountDiscount() {
        Account acc = createAccount('Test Account Bronze', 'Bronze');
        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        Integer discount = manager.getDiscount();
        Test.stopTest();
        
        // Assert that the correct discount is returned for the Bronze tier
        System.assertEquals(5, discount, 'The discount for Bronze should be 5%.');
    }
 
    @isTest static void testGetSilverAccountDiscount() {
        Account acc = createAccount('Test Account Silver', 'Silver');
        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        Integer discount = manager.getDiscount();
        Test.stopTest();
        
        // Assert that the correct discount is returned for the Silver tier
        System.assertEquals(10, discount, 'The discount for Silver should be 10%.');
    }

    @isTest static void testGetGoldAccountDiscount() {
        Account acc = createAccount('Test Account Gold', 'Gold');
        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        Integer discount = manager.getDiscount();
        Test.stopTest();
        
        // Assert that the correct discount is returned for the Gold tier
        System.assertEquals(15, discount, 'The discount for Gold should be 15%.');
    }
    @isTest static void testAssignCustomerNoneTier() {
        Account acc = createAccount('Test Account for Tier', null);
        Order ord2 = createOrder(acc.Id); // Silver tier order
        createOrderItem(ord2.Id, 5000, 1); // Creates an OrderItem to populate the TotalAmount

        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        manager.refreshCustomerTier();
        Test.stopTest();

        // Reload the account to check if tier was updated
        acc = [SELECT Customer_Tier__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        
        // Assert that the account has been upgraded to Silver tier
        System.assertEquals(null, acc.Customer_Tier__c, 'The account should have been assigned the None tier.');
    }
    @isTest static void testAssignCustomerBronzeTier() {
        Account acc = createAccount('Test Account for Tier', null);
        Order ord2 = createOrder(acc.Id); // Silver tier order
        createOrderItem(ord2.Id, 10000, 1); // Creates an OrderItem to populate the TotalAmount
        activateOrder(ord2);
        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        manager.refreshCustomerTier();
        Test.stopTest();

        // Reload the account to check if tier was updated
        acc = [SELECT Customer_Tier__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        
        // Assert that the account has been upgraded to Silver tier
        System.assertEquals('Bronze', acc.Customer_Tier__c, 'The account should have been assigned the Bronze tier.');
    }
    @isTest
    static void testAssignCustomerSilverTier() {
        Account acc = createAccount('Test Account for Tier', null);
        Order ord2 = createOrder(acc.Id); // Silver tier order
        createOrderItem(ord2.Id, 20000, 1); // Creates an OrderItem to populate the TotalAmount
        activateOrder(ord2);

        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        manager.refreshCustomerTier();
        Test.stopTest();

        // Reload the account to check if tier was updated
        acc = [SELECT Customer_Tier__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        
        // Assert that the account has been upgraded to Silver tier
        System.assertEquals('Silver', acc.Customer_Tier__c, 'The account should have been assigned the Silver tier.');
    }
    
    @isTest
    static void testAssignCustomerGoldTier() {
        Account acc = createAccount('Test Account for Tier', null);
        Order ord2 = createOrder(acc.Id); // Silver tier order
        createOrderItem(ord2.Id, 50000, 1); // Creates an OrderItem to populate the TotalAmount
        activateOrder(ord2);
        customerTierManager manager = new customerTierManager(acc.Id);
        
        Test.startTest();
        manager.refreshCustomerTier();
        Test.stopTest();

        // Reload the account to check if tier was updated
        acc = [SELECT Customer_Tier__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        
        // Assert that the account has been upgraded to Silver tier
        System.assertEquals('Gold', acc.Customer_Tier__c, 'The account should have been assigned the Gold tier.');
    }

    @isTest
    static void testGetCustomerTierData() {
        Account acc = createAccount('Test Account Tier Data', 'Bronze');
        Order ord = createOrder(acc.Id);
        createOrderItem(ord.Id, 10000, 1);  // TotalAmount = 10000
        activateOrder(ord);

        Order ord2 = createOrder(acc.Id);
        createOrderItem(ord2.Id, 10000, 1);  // TotalAmount = 10000
        activateOrder(ord2);

        Test.startTest();
        Map<String, Object> tierData = customerTierManager.getCustomerTierData('Test Account Tier Data');
        Test.stopTest();
        
        System.assertNotEquals(null, tierData.get('currentTier'), 'Tier data should not be null.');
        System.assertEquals('Silver', tierData.get('currentTier'), 'Current tier should be Bronze.');
        
        // Validate that tier data contains expected tiers
        List<Map<String, Object>> tiers = (List<Map<String, Object>>) tierData.get('tiers');
        System.assertNotEquals(0, tiers.size(), 'There should be at least one tier data.');
        
        // Validate total savings
        Decimal totalSavings = (Decimal) tierData.get('totalSavings');
        System.assertEquals(500, totalSavings, 'Total savings should be 500 for Bronze tier.');
    }

    @isTest
    static void testNoAccountException() {
        Test.startTest();
        try {
            // This should throw an exception since no account with the provided name exists
            customerTierManager.getCustomerTierData('Non-Existent Account');
            System.assert(false, 'Expected exception for non-existent account was not thrown.');
        } catch (customerTierManager.applicationException ex) {
            System.assertEquals('account by this name does not exist', ex.getMessage(), 'Exception message should match.');
        }
        Test.stopTest();
    }
    // Utility method to create sample data
    public static Account createAccount(String name, String customerTier) {
        Account acc = new Account(Name = name, Customer_Tier__c = customerTier);
        insert acc;
        return acc;
    }
    public static Order createOrder(Id accountId) {
        Order ord = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;
        return ord;
    }
    // Method to create OrderItem records to populate Order's TotalAmount
    public static OrderItem createOrderItem(Id orderId, Decimal unitPrice, Integer quantity) {
        // Create a PriceBook and PriceBookEntry for OrderItem
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPriceBook.Id,
            Product2Id = prod.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;

        Order order = [SELECT Id FROM Order WHERE Id = :orderId LIMIT 1];
        Order.Pricebook2Id = standardPricebook.Id;
        update order;

        OrderItem ordItem = new OrderItem(
            OrderId = orderId,
            Quantity = quantity,
            UnitPrice = unitPrice,
            PricebookEntryId = pbe.Id 
        );
        insert ordItem;
        return ordItem;
    }
    public static void activateOrder(Order order) {
        order.Status = 'Activated';
        update order;
    }
}
