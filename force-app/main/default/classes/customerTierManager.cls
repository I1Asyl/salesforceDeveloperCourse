public with sharing class customerTierManager {
    private Integer bronzePercent = 5, silverPercent = 10, goldPercent = 15;
    private Integer bronzeAmount = 10000, silverAmount = 20000, goldAmount = 40000;
    private Id  accountId;
    public class applicationException extends Exception {}
    
    //construtor for the class
    public customerTierManager(Id accountId) {
        this.accountId = accountId;
    }
    //get discount of the given user
    public Integer getDiscount() {
        Account acc = [SELECT Id, Customer_Tier__c FROM Account WHERE Id = :this.accountId LIMIT 1];

        if (acc.Customer_Tier__c == 'Gold') {
            return this.goldPercent;
        } 
        else if (acc.Customer_Tier__c == 'Silver') {
            return this.silverPercent;
        } 
        else if (acc.Customer_Tier__c == 'Bronze') {
            return this.bronzePercent;
        } 

        return 0;
    }
    // refresh customer tier(apply if the changes to orders happen or new orders are inserted)
    public void refreshCustomerTier() {
        AggregateResult[] groupedResults = [SELECT SUM(TotalAmount)sum
                                   FROM Order 
                                   WHERE AccountId = :this.accountId AND Status = 'Activated'
                                   AND CreatedDate = LAST_N_DAYS:365 ];
        Decimal totalOrderValue = (Decimal) groupedResults[0].get('sum');

        Account acc = [SELECT Id, Customer_Tier__c FROM Account WHERE Id = :this.accountId LIMIT 1];
        
        if (totalOrderValue >= this.goldAmount) {
            acc.Customer_Tier__c = 'Gold';
        } 
        else if (totalOrderValue >= this.silverAmount) {
            acc.Customer_Tier__c = 'Silver';
        } 
        else if (totalOrderValue >= this.bronzeAmount) {
            acc.Customer_Tier__c = 'Bronze';
        } 
        else {
            acc.Customer_Tier__c = null;
        }
        
        update acc;
    }
    // retrieve account tier data for frontend
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCustomerTierData(String accountName) {

        Map<String, Object> resultData = new Map<String, Object>();

        List<Account> accList = [SELECT Id, Customer_Tier__c FROM Account WHERE Name = :accountName LIMIT 1];
        if (accList == null || accList.size() == 0) {
            throw new applicationException('account by this name does not exist');
        }
        Account acc = accList[0];
        resultData.put('currentTier', acc.Customer_Tier__c);

        List<Map<String, Object>> tierList = new List<Map<String, Object>>();
 
        List<Order> results = [SELECT TotalAmount, Amount_After_Discount__c, Discount_Percentage__c, CreatedDate 
                                            FROM Order WHERE AccountId = :acc.Id];
            
        if (results == null || results.size() == 0) {
            return new Map<String, Object>();
        }
        for (Order result : results) {
            Decimal percent = (Decimal) result.get('Discount_Percentage__c');
            String tierName = 'No';
            if (percent == 5) {
                tierName = 'Bronze';
            } 
            else if (percent == 10) {
                tierName = 'Silver';
            } 
            else if (percent == 15) {
                tierName = 'Gold';
            } 
            Decimal totalAmount = (Decimal) result.get('TotalAmount'); 
            Decimal discountAmount = (Decimal) result.get('Amount_After_Discount__c'); // total amount saved in this tier
            Decimal savedAmount = totalAmount - discountAmount;
            DateTime tierAssignedDateTime = (DateTime) result.get('CreatedDate'); // assumed to be CreatedDate of the first order in that tier
            Boolean exists = false;
            for (Map<String, Object> data : tierList) {
                String tempName = (String) data.get('name');
                if (tierName != tempName) {
                    continue;
                }
                exists = true;
                Decimal newSavedAmount = (Decimal) data.get('savedAmount');
                DateTime newAssignedDateTime = (DateTime) data.get('assignedDateTime');
                newSavedAmount += savedAmount;
                if (newAssignedDateTime > tierAssignedDateTime) {
                    newAssignedDateTime = tierAssignedDateTime;
                }

                data.put('savedAmount', newSavedAmount);
                data.put('assignedDateTime', newAssignedDateTime);
            }

            if (!exists) {
                Map<String, Object> tierData = new Map<String, Object>();
                tierData.put('name', tierName);
                tierData.put('assignedDate', tierAssignedDateTime);
                tierData.put('savedAmount', savedAmount);
                tierList.add(tierData);
            }
        }

        resultData.put('tiers', tierList);

        // Calculate total savings (this is a sum of all tiers)
        Decimal totalSavings = 0;
        for (Map<String, Object> tier : tierList) {
            DateTime standardTime = (DateTime)tier.get('assignedDate');
            tier.put('assignedDate', standardTime.format('yyyy-MM-dd h:mm a'));
            totalSavings += (Decimal) tier.get('savedAmount');
        }
        resultData.put('totalSavings', totalSavings);

        return resultData;
    }
}

