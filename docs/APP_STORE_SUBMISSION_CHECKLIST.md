# App Store Submission Checklist

## Required URLs (from GitHub Repository)

### Support URL
```
https://github.com/derekwalsh1/nawgj
```

### Marketing URL (Optional but Recommended)
```
https://github.com/derekwalsh1/nawgj/blob/master/docs/APP_STORE_MARKETING.md
```

### Privacy Policy URL (Required)
```
https://github.com/derekwalsh1/nawgj/blob/master/docs/PRIVACY.md
```

### Terms of Service URL (Optional)
```
https://github.com/derekwalsh1/nawgj
```

---

## App Information Checklist

### ✅ Basic Information
- [x] App Name: **NAWGJ Expense Tracker**
- [x] Subtitle: **Gymnastics Judge Meet & Expense Management**
- [x] Primary Category: **Business**
- [x] Secondary Category: **Productivity** (optional)
- [x] Content Rights: You own all rights

### ✅ Pricing and Availability
- [x] Price: **Free** (or set your price)
- [x] Availability: **All Countries**
- [x] Release: **Automatic** or **Manual**

### ✅ Version Information
- [x] Version Number: **1.0**
- [x] Copyright: **© 2026 Derek Walsh**
- [x] Age Rating: **4+**

---

## App Store Copy Checklist

### ✅ Text Content (All in APP_STORE_COPY.md)
- [x] App Description (4000 char max) - ✓ Created
- [x] Promotional Text (170 char max) - ✓ Created
- [x] Keywords (100 char max, comma-separated) - ✓ Created
- [x] What's New (4000 char max) - ✓ Created
- [x] Support URL - ✓ Created
- [x] Marketing URL - ✓ Created
- [x] Privacy Policy URL - ✓ Created

### ✅ Privacy Details
- [x] Data Not Collected - ✓ Configured
- [x] Privacy Policy - ✓ Created (PRIVACY.md)

---

## Screenshot Requirements

### iPhone Screenshots (Required)
**6.7" Display (iPhone 14 Pro Max, 15 Pro Max)**
- [ ] 1-10 screenshots
- Size: 1290 x 2796 pixels
- Format: PNG or JPG

**Recommended Screenshots:**
1. Meet List view
2. Meet Detail with judges and summary
3. Judge Invoice PDF preview
4. Expense entry screen
5. Meet Report PDF preview

### iPad Screenshots (Required)
**12.9" Display (iPad Pro)**
- [ ] 1-10 screenshots  
- Size: 2048 x 2732 pixels
- Format: PNG or JPG

**Recommended Screenshots:**
1. Meet List (landscape)
2. Meet Detail (split view)
3. Judge Management
4. PDF Invoice (full page)
5. Reports view

### Screenshot Tips
- Use the sample meet data (SampleMeet.json) for realistic content
- Show different app states (empty, populated, PDFs)
- Use consistent branding/colors
- Add descriptive captions (30 char limit per screenshot)
- Consider using a screenshot framing tool

---

## App Preview Video (Optional but Recommended)

### iPhone App Preview
- Duration: 15-30 seconds
- Resolution: 1080 x 1920 pixels (portrait)
- Format: .mov, .m4v, or .mp4

### iPad App Preview
- Duration: 15-30 seconds
- Resolution: 1200 x 1600 pixels (portrait) or 1600 x 1200 (landscape)
- Format: .mov, .m4v, or .mp4

### Video Content Suggestions
1. Opening: App icon and title
2. Create a new meet
3. Add judges to meet
4. Add expenses
5. Generate and share invoice
6. Closing: App name and tagline

---

## App Icon Requirements

### App Store Icon
- [x] Size: 1024 x 1024 pixels
- [x] Format: PNG (no transparency)
- [x] Color Space: RGB
- [x] No rounded corners (App Store adds them)
- Located at: `/Graphics/AppLogoFullSize1024x1024.png`

---

## Build Checklist

### ✅ Xcode Configuration
- [ ] Version number set (1.0)
- [ ] Build number set (1)
- [ ] Bundle identifier correct
- [ ] Team/signing configured
- [ ] Deployment target set (iOS 14.0+)
- [ ] Build for Generic iOS Device
- [ ] Archive created
- [ ] Archive validated (no errors)
- [ ] Archive uploaded to App Store Connect

### ✅ App Capabilities
- [ ] Required capabilities enabled
- [ ] Background modes (if any) configured
- [ ] Privacy usage descriptions added (if needed)

---

## App Review Information

### Contact Information
- [ ] First Name: Derek
- [ ] Last Name: Walsh  
- [ ] Email Address: ________________
- [ ] Phone Number: ________________

### Demo Account
- [ ] Not Required (app doesn't require login)

### Notes for Reviewer
```
Thank you for reviewing NAWGJ Expense Tracker!

The app includes comprehensive sample data for testing:
- Import "SampleMeet.json" from the TestData folder
- This loads a complete 3-day meet with 25 judges
- Demonstrates all features: fees, expenses, PDF generation

Key features to test:
1. Create new meet: Tap "+" in Meets list
2. Add judges from roster
3. Add expenses (mileage, lodging, etc.)
4. Generate invoice: Tap judge → View Invoice
5. Generate report: Tap meet → View Report
6. Export: Use Export button

No internet connection required. All data stored locally.
```

### Attachments
- [ ] Sample screenshots showing key features (optional)
- [ ] Demo video if complex features (optional)

---

## Age Rating Questionnaire

All answers: **NO**
- [ ] Made for Kids: **No**
- [ ] Contests: **No**
- [ ] Gambling: **No**
- [ ] Alcohol/Tobacco/Drugs: **No**
- [ ] Mature Themes: **No**
- [ ] Profanity: **No**
- [ ] Horror: **No**
- [ ] Medical Info: **No**
- [ ] Violence: **No**
- [ ] Sexual Content: **No**

**Result: 4+**

---

## Pre-Submission Checklist

### ✅ Testing
- [ ] Test on physical iPhone device
- [ ] Test on physical iPad device
- [ ] Test all major features
- [ ] Test with sample data import
- [ ] Test PDF generation
- [ ] Test export functionality
- [ ] Test on different iOS versions (14.0+)
- [ ] No crashes or major bugs
- [ ] App performs smoothly

### ✅ Content Review
- [ ] No placeholder content
- [ ] All text is final
- [ ] No typos in UI
- [ ] All images properly sized
- [ ] App icon looks good
- [ ] Screenshots are high quality

### ✅ Compliance
- [ ] Privacy Policy published and accessible
- [ ] No data collection without disclosure
- [ ] No unauthorized API usage
- [ ] Follows Apple Human Interface Guidelines
- [ ] Complies with App Store Review Guidelines

---

## Submission Steps

### 1. Prepare in Xcode
```bash
# In Xcode:
1. Select "Any iOS Device (arm64)" as destination
2. Product → Archive
3. Wait for archive to complete
4. Validate archive (check for issues)
5. Distribute App → App Store Connect
6. Upload
```

### 2. Configure in App Store Connect
1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill in app information
4. Add version 1.0
5. Upload screenshots
6. Add description, keywords, etc.
7. Set pricing
8. Configure privacy details
9. Select build
10. Submit for review

### 3. After Submission
- [ ] Monitor status in App Store Connect
- [ ] Respond to any reviewer questions within 24 hours
- [ ] Check email for updates
- [ ] Be ready to fix issues if rejected

---

## Post-Approval Checklist

### ✅ When Approved
- [ ] Review app listing in App Store
- [ ] Test downloading from App Store
- [ ] Share with friends/colleagues for feedback
- [ ] Monitor reviews and ratings
- [ ] Respond to user reviews
- [ ] Plan next version updates

### ✅ Marketing
- [ ] Share on social media
- [ ] Post in NAWGJ communities
- [ ] Email gymnastics judge organizations
- [ ] Create demo video for website
- [ ] Update GitHub README with App Store badge

---

## Common Rejection Reasons & How to Avoid

### Metadata Rejection
- ✓ **Avoided:** All descriptions are clear and accurate
- ✓ **Avoided:** Screenshots show actual app functionality
- ✓ **Avoided:** Keywords are relevant
- ✓ **Avoided:** No misleading content

### Privacy Issues
- ✓ **Avoided:** Privacy policy is clear and published
- ✓ **Avoided:** No data collection disclosed
- ✓ **Avoided:** No tracking or analytics

### App Completeness
- ✓ **Avoided:** App is fully functional
- ✓ **Avoided:** No "Coming Soon" features
- ✓ **Avoided:** All features work as described
- ✓ **Avoided:** Sample data available for testing

### Design Issues
- ✓ **Avoided:** Follows iOS design guidelines
- ✓ **Avoided:** Proper navigation
- ✓ **Avoided:** Good user experience
- ✓ **Avoided:** Professional appearance

---

## Support Resources

### Apple Resources
- App Store Connect: https://appstoreconnect.apple.com
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/

### Your App Resources
- GitHub Repository: https://github.com/derekwalsh1/nawgj
- Privacy Policy: https://github.com/derekwalsh1/nawgj/blob/master/PRIVACY.md
- Sample Data: /NawgjExpenseTracker/TestData/
- Documentation: README.md

---

## Quick Reference URLs

Copy these directly into App Store Connect:

**Support URL:**
```
https://github.com/derekwalsh1/nawgj
```

**Privacy Policy URL:**
```
https://github.com/derekwalsh1/nawgj/blob/master/docs/PRIVACY.md
```

**Marketing URL:**
```
https://github.com/derekwalsh1/nawgj/blob/master/docs/APP_STORE_MARKETING.md
```

---

**Good luck with your submission! 🚀**

