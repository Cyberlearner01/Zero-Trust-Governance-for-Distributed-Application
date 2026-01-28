# Hybrid Zero-Trust Governance Lab (Azure + Terraform)

## Project Overview

I built this lab to demonstrate how Zero Trust governance is applied in real Azure environments, not just how infrastructure is deployed.

I created two web apps. In this lab, I focused on why access is granted, how it is controlled, and how privilege is reduced over time. The goal was to design an environment where identities, permissions, and secrets are governed intentionally and auditable from day one.

The environment consists of:

* An Internal Line-of-Business (LOB) application
* A Customer Portal application
* Centralized governance using RBAC, Managed Identities, Conditional Access, and Privileged Identity Management (PIM)

All infrastructure is deployed using Terraform, with identity and access governance layered on top using native Azure and Microsoft Entra ID controls.

---

## Step 1 Provider Configuration

I started by configuring the AzureRM provider and enabling Key Vault soft-delete recovery features.

I did this early because Key Vault is a sensitive service, and in real enterprise environments accidental deletion is protected against by default. Even in a lab, I wanted safer operational defaults that reflect production standards.

---

## Step 2 Resource Group as a Governance Boundary

I created a single resource group called `rg-zero-trust-governance` to contain all resources for this lab.

---

## Step 3 Separate App Service Plans for Isolation

I created two separate Linux App Service Plans:

* one for the Internal LOB application
* and the other for the Customer Portal application

Although a single plan would have worked for a basic lab, I separated them to mirror how production workloads are typically isolated. This prevents unnecessary coupling, supports independent scaling, and reinforces the idea that each application is its own security unit.

---

## Step 4 Deploy Web Apps with Managed Identities

I then deployed two Linux Web Apps:

* `app-internal-lob-seclab`
* `app-customer-portal-seclab`

Each web app was configured with a system-assigned managed identity.

I created a system-assigned managed identity so the app can read its own secret from Key Vault without storing any credentials. The app is recognized by its identity at runtime, access is checked automatically, and when the app is deleted the identity and its access disappear with it.

---

## Step 5 Azure Key Vault with RBAC Enabled

After the applications and their identities existed, I deployed an Azure Key Vault with RBAC authorization enabled.

I chose RBAC instead of traditional Key Vault access policies because RBAC aligns with centralized governance models used in enterprise environments. It allows access to be audited consistently and managed alongside other Azure permissions.

<img width="1722" height="713" alt="Screenshot 2026-01-28 111101" src="https://github.com/user-attachments/assets/f288bc9d-0bd6-4ca2-9594-4b56315eed33" />

---

## Step 6 Secure Secret Management

Sensitive values, such as database passwords are stored in Azure Key Vault and referenced from the web apps using Key Vault references.

This ensures that:

* no secrets exist in source code
* no secrets are stored in app settings as plain text
* no secrets are exposed in GitHub or Terraform outputs

---

## Step 7 Least-Privilege Access to Secrets

To enforce least privilege, I separated Key Vault access based on what each identity actually needs to do. I gave Terraform permission to create and manage secrets because it’s responsible for deploying the infrastructure. 

The applications themselves only have read access to the secrets they need at runtime and cannot change or delete anything. This way, the app can use a secret but it never has the ability to manage or alter it.

---

## Step 8 Identity Governance with Entra ID Groups

Rather than assigning permissions directly to individuals, I introduced Microsoft Entra ID security groups to manage access:

* `InternalLOB-App-Users`
* `CustomerPortal-App-Users`
* `ZeroTrust-Readers`

 <img width="1831" height="626" alt="image" src="https://github.com/user-attachments/assets/aa6add2d-7381-4026-8c0b-c178686a7570" />



Using groups reflects real organizational practices and simplifies onboarding, offboarding, and access reviews.

---

## Step 9 Scoped RBAC for Administrative Access

Azure RBAC was applied using the tightest possible scope:

* Internal LOB admins have Website Contributor access only to the Internal LOB app


<img width="1140" height="461" alt="Screenshot 2026-01-28 114024" src="https://github.com/user-attachments/assets/4c4d9a69-ee4c-4afb-9351-3c4b94493f42" />

* Customer Portal admins have Website Contributor access only to the Customer Portal app

  <img width="1203" height="543" alt="Screenshot 2026-01-28 114125" src="https://github.com/user-attachments/assets/440adae1-56ad-480e-883f-745a8591361e" />
  

* Readers have Reader access at the resource group level

  <img width="1493" height="630" alt="Screenshot 2026-01-28 114243" src="https://github.com/user-attachments/assets/50ce4a4b-db89-4e68-8528-1171c47ded7b" />


This prevents over-privileged access and ensures administrators can manage only what they are responsible for.

---

## Step 10 Privileged Identity Management (PIM)

To remove standing administrative privileges, RBAC assignments were configured as Eligible using Privileged Identity Management.

With this model:

* users have no access by default
* access must be explicitly activated
* privileges are time-bound
* all actions are logged and auditable

  <img width="1341" height="713" alt="Screenshot 2026-01-28 114504" src="https://github.com/user-attachments/assets/6ca07449-69a4-4070-9dfa-e43ecfe250db" />


This aligns with the Zero Trust principle that privilege should be temporary and intentional.

---

## Step 11 Application Authentication with Microsoft Entra ID

With infrastructure and administrative governance in place, I enforced application-level authentication.

Both applications use App Service Authentication with Microsoft Entra ID. Authentication is handled by the platform, not application code, ensuring consistent enforcement and reducing implementation risk.

The Internal LOB app is configured as single-tenant, while the Customer Portal supports external identities, reflecting their different access requirements.

<img width="1844" height="812" alt="Screenshot 2026-01-28 120604" src="https://github.com/user-attachments/assets/e0f6b631-6977-45d9-9b36-00f176ccfb48" />


---

## Step 12 Internal LOB Application Access Model

The Internal LOB application is treated as a high-trust internal system.

Authentication alone was not considered sufficient. The Enterprise Application is configured with “Assignment required” enabled, which means users cannot access the app unless they are explicitly assigned.

Access is granted through a dedicated group:

* `InternalLOB-App-Users`

  <img width="318" height="877" alt="Screenshot 2026-01-28 123943" src="https://github.com/user-attachments/assets/1419a87c-1a54-42d0-8084-2b0616c83ddc" />


A Conditional Access policy enforces multi-factor authentication (MFA) for all sign-ins. Vendors are invited as guest users, added to the group only when needed, and removed immediately after access is no longer required.

---

## Step 13 Customer Portal Access Model (Single Tenant, External Users)

The Customer Portal uses a different trust model while remaining in the same tenant.

Customers authenticate using Microsoft identity, but access is never assumed. The Enterprise Application is configured with “Assignment required” enabled, ensuring that only explicitly entitled users can access the portal.

Access is controlled through:

* `CustomerPortal-App-Users`

A separate Conditional Access policy enforces MFA for customer access. This reduces the risk of credential compromise while keeping the model simple and auditable.

---

## Step 14 Conditional Access as Enforcement, Not Entitlement

Conditional Access is used strictly as an enforcement mechanism, not as the source of entitlement.

Entitlement is defined by:

* Enterprise Application assignment
* Group membership

Conditional Access enforces:

* MFA requirements
* consistent sign-in security

This separation keeps access decisions clear, predictable, and easy to audit.

Assignment required on the Enterprise Application is what enforces true authorization, while Conditional Access adds security requirements on top of that access.


---

## Final Architecture and Zero Trust Outcomes

At the end of this lab, the environment reflects a real-world Zero Trust design:

* Authentication is enforced for all applications
* Authorization is explicit and group-based
* Application access requires assignment, not just identity
* MFA is enforced through Conditional Access
* Secrets are retrieved securely using managed identities
* Administrative access is just-in-time and least-privileged
* Internal users, vendors, and customers are handled using distinct trust models

  Access test with user assigned to the application

I tested the customer portal by adding Chris to the CustomerPortal-App-Users group. Once he was in the group, he was able to sign in and access the portal without any issues, which confirmed that group assignment grants access.
<img width="646" height="721" alt="Screenshot 2026-01-28 131507" src="https://github.com/user-attachments/assets/44b40ad6-635e-4368-a3e6-46c9814dd834" />

<img width="1685" height="591" alt="Screenshot 2026-01-28 131533" src="https://github.com/user-attachments/assets/21e4eb77-07c8-4686-b541-b723bc280b6c" />

Access test with user not assigned to the application


I then removed Chris from the CustomerPortal-App-Users group and tested again. This time he was blocked from accessing the portal, which confirmed that access is enforced based on group membership and not just successful authentication.
<img width="727" height="577" alt="Screenshot 2026-01-28 132838" src="https://github.com/user-attachments/assets/76eb12bf-1270-4058-81bc-43a9cacc6d08" />


This project demonstrates not just how to deploy Azure resources, but how to design intentional access, strong identity boundaries, and enforceable governance that mirrors how Zero Trust is applied in real enterprise environments.
