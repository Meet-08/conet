# Razorpay Route – Linked Account (Node.js)

### Quick Summary

To create a Linked Account for Route payments using Node.js:

Initialize Razorpay client
Prepare account payload
Call accounts.create()

1. Initialize Razorpay Client

```js
const Razorpay = require("razorpay");

const razorpay = new Razorpay({
  key_id: process.env.RAZOR_PAY_KEY_ID,
  key_secret: process.env.RAZOR_PAY_KEY_SECRET,
});
```

2. Create Linked Account Payload

```js
const linkedAccBody = {
  email: "merchant@example.com",
  phone: "9620107401",
  type: "route",
  legal_business_name: "Merchant Business",
  business_type: "individual",
  contact_name: "Merchant Name",
  profile: {
    category: "services",
    subcategory: "automotive_service_shops",
    addresses: {
      registered: {
        street1: "HSR layout",
        street2: "HSR",
        city: "Bangalore",
        state: "KARNATAKA",
        postal_code: "560041",
        country: "India",
      },
    },
  },
  legal_info: {
    pan: "AAACL1234C",
    gst: "36AAECL6705C1ZS", // optional
  },
};
```

3.  Create Linked Account

```js
try {
  const res = await razorpay.accounts.create(linkedAccBody);
  console.log("Linked Account Created:", res.id);
} catch (error) {
  console.error("Error:", error);
}
```

### Minimum Required Vendor Info

Required fields:

- email
- phone
- type = "route"
- legal_business_name
- business_type (e.g. individual)
- contact_name
- profile
- category
- subcategory
- addresses.registered
- legal_info.pan

Optional:

- legal_info.gst (only if GST registered)

### Notes & Constraints

- KYC Required → Mandatory before payouts
- PAN Validation → Strict validation
- Route Feature → Must be enabled
- Account ID → Used for transfers
- API Endpoint → /v2/accounts
- Event Platform Use Case

This approach is suitable for:

- Event marketplace platforms
- Individual organizers creating events
- Users paying for tickets

### Flow

1. Organizer signs up → Linked Account created
2. User pays for event
3. Payment split:
   - Organizer → gets share
   - Platform → keeps commission

### KYC Considerations

- Can create account with minimal data
- Settlements are blocked until KYC is complete
- CKYC users → faster verification

#### With CKYC

Even with CKYC, required fields remain the same:

- email
- phone
- legal_business_name
- business_type
- contact_name
- profile
- PAN

CKYC only speeds up verification, not creation.

### Legal Info Requirement

- PAN is mandatory
- GST is optional

### Using Event Title as Business Name

Allowed if:

- 4–200 characters
- Only letters, numbers, and spaces
- No special characters, links, or HTML

### Activation Steps

To enable payouts:

1. Create Linked Account
2. Add Stakeholder (if required)
3. Request Route product configuration
4. Add bank details:
   - account number
   - IFSC
   - beneficiary_name
5. Complete KYC

### Settlement Requirements

- beneficiary_name is required
- Must match:
  - bank account name
  - legal business name

### Incorrect Beneficiary Name

- No penalty
- But:
  - Penny test fails
  - Account not activated

### Important Rule

- Bank account must belong to organizer
- Cannot use someone else’s (e.g., father’s account)

### Defaults You Can Set (Platform Side)

You can auto-fill:

- category: "events"
- subcategory: "event_management"

Optional defaults:

- customer_facing_business_name (e.g., event title)

### Optional Fields

- reference_id → only if Route feature enabled
