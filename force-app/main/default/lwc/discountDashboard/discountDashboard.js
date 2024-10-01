import { LightningElement, wire, track, api } from 'lwc';
import getCustomerTierData from '@salesforce/apex/customerTierManager.getCustomerTierData';

export default class CustomerTierDashboard extends LightningElement {
    tierData; error; isLoading = true; inputName;
    @api accountName;
    
    handleInputChange(event) {
        this.inputName = event.target.value;
    }
    handleSearchClick() {
        this.accountName = this.inputName;
    }
    // Use wire to get customer tier data from the server
    @wire(getCustomerTierData, { accountName: '$accountName' })
    wiredTierData({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.tierData = data;
            this.error = undefined;
        } else if (error) {
            this.error = 'An error occurred while retrieving data: ' + error.body.message;
            this.tierData = undefined;
        }
    }
}
