/**
 * Atlas Tourism - Client-Side Interactive Scripts
 * Handles password visibility toggles, booking calculations, and interactive UI.
 */

document.addEventListener('DOMContentLoaded', function () {
    // Hero Search Destination Custom Dropdown Selection
    const heroDestInput = document.getElementById('hero-destination-id');
    const heroDestLabel = document.getElementById('hero-destination-label');
    const heroDestItems = document.querySelectorAll('.hero-dest-item');

    if (heroDestItems.length > 0) {
        heroDestItems.forEach(item => {
            item.addEventListener('click', function (e) {
                e.preventDefault();
                const val = this.getAttribute('data-value') || '';
                const lbl = this.getAttribute('data-label') || 'All Destinations';

                if (heroDestInput) heroDestInput.value = val;
                if (heroDestLabel) heroDestLabel.textContent = lbl;

                heroDestItems.forEach(el => {
                    el.classList.remove('active');
                    const check = el.querySelector('.check-indicator');
                    if (check) check.classList.add('d-none');
                });

                this.classList.add('active');
                const check = this.querySelector('.check-indicator');
                if (check) check.classList.remove('d-none');
            });
        });
    }

    // 1. Password Visibility Toggle
    const passwordToggles = document.querySelectorAll('.password-toggle-btn');
    passwordToggles.forEach(button => {
        button.addEventListener('click', function () {
            const targetInputId = this.getAttribute('data-target');
            const targetInput = document.getElementById(targetInputId);
            const icon = this.querySelector('i');

            if (targetInput) {
                if (targetInput.type === 'password') {
                    targetInput.type = 'text';
                    icon.classList.remove('bi-eye');
                    icon.classList.add('bi-eye-slash');
                } else {
                    targetInput.type = 'password';
                    icon.classList.remove('bi-eye-slash');
                    icon.classList.add('bi-eye');
                }
            }
        });
    });

    // 2. Dynamic Booking Price Calculation
    const packagePriceEl = document.getElementById('calc-package-price');
    const adultsInput = document.getElementById('calc-adults');
    const childrenInput = document.getElementById('calc-children');
    const baseAmountDisplay = document.getElementById('calc-base-amount');
    const discountDisplay = document.getElementById('calc-discount-amount');
    const totalDisplay = document.getElementById('calc-total-amount');
    const offerCodeInput = document.getElementById('calc-offer-code');
    const applyOfferBtn = document.getElementById('calc-apply-offer-btn');
    const offerFeedback = document.getElementById('calc-offer-feedback');
    const travellersContainer = document.getElementById('travellers-container');

    let appliedDiscountPercent = 0;

    function updateBookingSummary() {
        if (!packagePriceEl || !adultsInput) return;

        const pricePerAdult = parseFloat(packagePriceEl.value) || 0;
        const adults = parseInt(adultsInput.value) || 1;
        const children = childrenInput ? (parseInt(childrenInput.value) || 0) : 0;

        // Children charged at 60% of base package rate
        const adultsTotal = adults * pricePerAdult;
        const childrenTotal = children * (pricePerAdult * 0.6);
        const baseTotal = adultsTotal + childrenTotal;

        const discountTotal = (baseTotal * appliedDiscountPercent) / 100;
        const grandTotal = Math.max(0, baseTotal - discountTotal);

        if (baseAmountDisplay) baseAmountDisplay.innerText = `₹${baseTotal.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
        if (discountDisplay) discountDisplay.innerText = `-₹${discountTotal.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
        if (totalDisplay) totalDisplay.innerText = `₹${grandTotal.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;

        // Hidden fields for form submission
        const baseField = document.getElementById('form-base-amount');
        const discountField = document.getElementById('form-discount-amount');
        const totalField = document.getElementById('form-total-amount');
        if (baseField) baseField.value = baseTotal.toFixed(2);
        if (discountField) discountField.value = discountTotal.toFixed(2);
        if (totalField) totalField.value = grandTotal.toFixed(2);

        // Dynamically adjust traveller input fields
        renderTravellerFields(adults, children);
    }

    function renderTravellerFields(adults, children) {
        if (!travellersContainer) return;
        const totalTravellers = adults + children;
        
        // Preserve existing values where possible
        const existingEntries = travellersContainer.querySelectorAll('.traveller-entry');
        const existingData = [];
        existingEntries.forEach(entry => {
            const name = entry.querySelector('input[name="traveller_name[]"]')?.value || '';
            const age = entry.querySelector('input[name="traveller_age[]"]')?.value || '';
            const gender = entry.querySelector('select[name="traveller_gender[]"]')?.value || 'Male';
            existingData.push({ name, age, gender });
        });

        travellersContainer.innerHTML = '';

        for (let i = 0; i < totalTravellers; i++) {
            const isChild = i >= adults;
            const label = isChild ? `Traveller ${i + 1} (Child)` : `Traveller ${i + 1} (Adult)`;
            const prev = existingData[i] || { name: '', age: isChild ? '8' : '28', gender: 'Male' };

            const row = document.createElement('div');
            row.className = 'traveller-entry card p-3 mb-3 border-light bg-light';
            row.innerHTML = `
                <div class="row g-2 align-items-center">
                    <div class="col-md-5">
                        <label class="form-label small fw-semibold text-muted mb-1">${label} Name</label>
                        <input type="text" name="traveller_name[]" class="form-control form-control-sm" placeholder="Full Name" value="${prev.name}" required>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label small fw-semibold text-muted mb-1">Age</label>
                        <input type="number" name="traveller_age[]" class="form-control form-control-sm" placeholder="Age" min="1" max="100" value="${prev.age}" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted mb-1">Gender</label>
                        <select name="traveller_gender[]" class="form-select form-select-sm" required>
                            <option value="Male" ${prev.gender === 'Male' ? 'selected' : ''}>Male</option>
                            <option value="Female" ${prev.gender === 'Female' ? 'selected' : ''}>Female</option>
                            <option value="Other" ${prev.gender === 'Other' ? 'selected' : ''}>Other</option>
                        </select>
                    </div>
                </div>
            `;
            travellersContainer.appendChild(row);
        }
    }

    if (adultsInput) {
        adultsInput.addEventListener('input', updateBookingSummary);
        adultsInput.addEventListener('change', updateBookingSummary);
    }
    if (childrenInput) {
        childrenInput.addEventListener('input', updateBookingSummary);
        childrenInput.addEventListener('change', updateBookingSummary);
    }

    // Coupon verification
    if (applyOfferBtn && offerCodeInput) {
        applyOfferBtn.addEventListener('click', function () {
            const code = offerCodeInput.value.trim().toUpperCase();
            if (!code) {
                if (offerFeedback) {
                    offerFeedback.className = 'small text-danger mt-1';
                    offerFeedback.innerText = 'Please enter a coupon code.';
                }
                return;
            }

            fetch(`/api/validate-offer?code=${encodeURIComponent(code)}`)
                .then(res => res.json())
                .then(data => {
                    if (data.valid) {
                        appliedDiscountPercent = data.discount_percent;
                        if (offerFeedback) {
                            offerFeedback.className = 'small text-success mt-1 fw-bold';
                            offerFeedback.innerText = `Coupon '${code}' applied successfully! (${data.discount_percent}% off)`;
                        }
                        const offerIdField = document.getElementById('form-offer-id');
                        if (offerIdField) offerIdField.value = data.offer_id;
                    } else {
                        appliedDiscountPercent = 0;
                        if (offerFeedback) {
                            offerFeedback.className = 'small text-danger mt-1';
                            offerFeedback.innerText = data.message || 'Invalid or expired offer code.';
                        }
                        const offerIdField = document.getElementById('form-offer-id');
                        if (offerIdField) offerIdField.value = '';
                    }
                    updateBookingSummary();
                })
                .catch(err => {
                    console.error('Error validating coupon:', err);
                });
        });
    }

    // Initialize calculations on booking page load
    if (packagePriceEl) {
        updateBookingSummary();
    }

    // 3. Wishlist Toggle Buttons
    document.querySelectorAll('.btn-wishlist-toggle').forEach(button => {
        button.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            const packageId = this.getAttribute('data-package-id');
            const icon = this.querySelector('i');

            fetch(`/wishlist/toggle/${packageId}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'unauthorized') {
                    window.location.href = '/login?next=' + encodeURIComponent(window.location.pathname);
                    return;
                }
                if (data.status === 'added') {
                    icon.classList.remove('bi-heart');
                    icon.classList.add('bi-heart-fill');
                    this.classList.add('active');
                } else if (data.status === 'removed') {
                    icon.classList.remove('bi-heart-fill');
                    icon.classList.add('bi-heart');
                    this.classList.remove('active');
                }
                // Update badge if present
                const badge = document.getElementById('wishlist-badge');
                if (badge && data.total_count !== undefined) {
                    badge.innerText = data.total_count;
                }
            })
            .catch(err => console.error('Wishlist error:', err));
        });
    });

    // 3.b Wishlist Destination Toggle Buttons
    document.querySelectorAll('.btn-wishlist-dest-toggle').forEach(button => {
        button.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            const destinationId = this.getAttribute('data-destination-id');
            const icon = this.querySelector('i');
            const textSpan = this.querySelector('span');

            fetch(`/wishlist/toggle-destination/${destinationId}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'unauthorized') {
                    window.location.href = '/login?next=' + encodeURIComponent(window.location.pathname);
                    return;
                }
                if (data.status === 'added') {
                    if (icon) {
                        icon.classList.remove('bi-heart');
                        icon.classList.add('bi-heart-fill');
                    }
                    this.classList.add('active');
                    if (textSpan) textSpan.textContent = 'Saved Destination';
                } else if (data.status === 'removed') {
                    if (icon) {
                        icon.classList.remove('bi-heart-fill');
                        icon.classList.add('bi-heart');
                    }
                    this.classList.remove('active');
                    if (textSpan) textSpan.textContent = 'Wishlist Destination';
                }
                // Update navbar badge if present
                const badge = document.getElementById('wishlist-badge');
                if (badge && data.total_count !== undefined) {
                    badge.innerText = data.total_count;
                }
            })
            .catch(err => console.error('Destination Wishlist error:', err));
        });
    });
});


// =========================================================
// AUTO-DISMISS FLASH NOTIFICATIONS AFTER 3 SECONDS
// Smoothly fades out floating alert toasts
// =========================================================
function setupAutoDismissAlerts() {
    function dismissAlert(alertEl) {
        if (!alertEl || alertEl.dataset.autoDismissSet) return;
        alertEl.dataset.autoDismissSet = 'true';

        setTimeout(function() {
            if (!document.body.contains(alertEl)) return;

            // Smooth fade out animation
            alertEl.style.transition = 'opacity 0.6s ease, transform 0.6s ease, max-height 0.6s ease, margin 0.6s ease, padding 0.6s ease';
            alertEl.style.opacity = '0';
            alertEl.style.transform = 'translateY(-12px)';

            setTimeout(function() {
                try {
                    if (window.bootstrap && window.bootstrap.Alert) {
                        const bsAlert = window.bootstrap.Alert.getOrCreateInstance(alertEl);
                        if (bsAlert) {
                            bsAlert.close();
                            return;
                        }
                    }
                } catch (e) {
                    // Fallback to DOM removal
                }
                if (alertEl.parentNode) {
                    alertEl.parentNode.removeChild(alertEl);
                }
            }, 600);
        }, 3000); // Exactly 3 seconds auto-dismiss
    }

    // Process all existing alerts immediately
    document.querySelectorAll('.alert.alert-dismissible').forEach(dismissAlert);

    // Watch for new alerts added dynamically to the DOM
    if (window.MutationObserver) {
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        if (node.classList && node.classList.contains('alert') && node.classList.contains('alert-dismissible')) {
                            dismissAlert(node);
                        }
                        if (node.querySelectorAll) {
                            node.querySelectorAll('.alert.alert-dismissible').forEach(dismissAlert);
                        }
                    }
                });
            });
        });
        observer.observe(document.body, { childList: true, subtree: true });
    }
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupAutoDismissAlerts);
} else {
    setupAutoDismissAlerts();
}

// =========================================================
// ON-SCREEN CANCEL TRIP CONFIRMATION MODAL HANDLER
// =========================================================
document.addEventListener('click', function(e) {
    const btn = e.target.closest('.btn-cancel-trip');
    if (!btn) return;

    e.preventDefault();
    const actionUrl = btn.getAttribute('data-action');
    const pkgName = btn.getAttribute('data-package') || '';

    const modalEl = document.getElementById('cancelTripModal');
    if (modalEl) {
        const formEl = document.getElementById('cancelTripConfirmForm');
        if (formEl) formEl.action = actionUrl;

        const nameEl = document.getElementById('cancelTripPackageName');
        if (nameEl) {
            if (pkgName) {
                nameEl.textContent = `"${pkgName}"`;
                nameEl.style.display = 'block';
            } else {
                nameEl.style.display = 'none';
            }
        }

        if (window.bootstrap && window.bootstrap.Modal) {
            const modal = window.bootstrap.Modal.getOrCreateInstance(modalEl);
            modal.show();
        }
    }
});
