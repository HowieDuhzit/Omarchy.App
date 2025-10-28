// Omarchy Directory Application JavaScript
// Production-ready JavaScript for the Omarchy WebApp Directory

class OmarchyApp {
  constructor() {
    this.adminMode = false;
    this.adminPassword = document.querySelector('meta[name="admin-password"]')?.content || 'omarchy2024';
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.setupKeyboardShortcuts();
    this.setupLiveSearch();
  }

  setupEventListeners() {
    // Modal close on outside click
    document.addEventListener('click', (event) => {
      const modals = ['appDetailsModal', 'addAppModal', 'helpModal', 'adminModal'];
      modals.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (event.target === modal) {
          this.closeModal(modalId);
        }
      });
    });

    // Modal close on Escape key
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        this.closeAllModals();
      }
    });
  }

  setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
      // Admin mode toggle: Ctrl+Shift+A
      if (event.ctrlKey && event.shiftKey && event.key === 'A') {
        event.preventDefault();
        this.toggleAdminMode();
      }
    });
  }

  setupLiveSearch() {
    const searchInput = document.querySelector('input[name="search"]');
    const cards = document.querySelectorAll('.card');
    const appsGrid = document.getElementById('apps-grid');
    
    if (searchInput && cards.length > 0) {
      // Add results counter
      const resultsCounter = document.createElement('div');
      resultsCounter.className = 'text-gray-400 text-sm mb-4 px-6';
      resultsCounter.id = 'results-counter';
      appsGrid.parentNode.insertBefore(resultsCounter, appsGrid);
      
      const updateResults = () => {
        const visibleCards = Array.from(cards).filter(card => 
          !card.style.display || card.style.display !== 'none'
        );
        resultsCounter.textContent = `${visibleCards.length} apps found`;
      };
      
      searchInput.addEventListener('input', (event) => {
        const searchTerm = event.target.value.toLowerCase().trim();
        
        cards.forEach(card => {
          const appName = card.dataset.appName.toLowerCase();
          const appCategory = card.dataset.appCategory.toLowerCase();
          
          if (searchTerm === '' || 
              appName.includes(searchTerm) || 
              appCategory.includes(searchTerm)) {
            card.style.display = '';
          } else {
            card.style.display = 'none';
          }
        });
        
        updateResults();
      });
      
      // Initial results count
      updateResults();
    }
  }

  // Modal Management
  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('hidden');
      modal.classList.add('flex');
      
      // Focus on password input for admin modal
      if (modalId === 'adminModal') {
        document.getElementById('adminPassword')?.focus();
      }
    }
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('hidden');
      modal.classList.remove('flex');
      
      // Clear password field for admin modal
      if (modalId === 'adminModal') {
        document.getElementById('adminPassword').value = '';
      }
    }
  }

  closeAllModals() {
    const modals = ['appDetailsModal', 'addAppModal', 'helpModal', 'adminModal'];
    modals.forEach(modalId => this.closeModal(modalId));
  }

  // App Details Modal
  showAppDetailsModal(card) {
    const appData = {
      id: card.dataset.appId,
      name: card.dataset.appName,
      url: card.dataset.appUrl,
      icon: card.dataset.appIcon,
      category: card.dataset.appCategory
    };

    this.updateModalContent(appData);
    this.openModal('appDetailsModal');
  }

  updateModalContent(appData) {
    const elements = {
      modalAppName: appData.name,
      modalAppTitle: appData.name,
      modalAppCategory: this.formatCategory(appData.category),
      modalAppUrl: appData.url,
      modalAppIcon: appData.icon,
      modalAppOpenLink: appData.url,
      modalAppInstallLink: `/webapps/${appData.id}/install`
    };

    Object.entries(elements).forEach(([id, value]) => {
      const element = document.getElementById(id);
      if (element) {
        if (id === 'modalAppIcon') {
          element.src = value;
        } else if (id === 'modalAppOpenLink' || id === 'modalAppInstallLink') {
          element.href = value;
        } else {
          element.textContent = value;
        }
      }
    });
  }

  formatCategory(category) {
    return category.charAt(0).toUpperCase() + 
           category.slice(1).replace('_', ' ');
  }

  // Admin Functions
  async authenticateAdmin() {
    const password = document.getElementById('adminPassword')?.value;
    
    try {
      const response = await fetch('/admin/authenticate', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json'
        },
        credentials: 'same-origin',
        body: JSON.stringify({ password: password })
      });
      
      const result = await response.json();
      
      if (result.success) {
        this.adminMode = true;
        this.closeModal('adminModal');
        this.toggleAdminMode();
        this.showNotification('Admin mode enabled', 'success');
      } else {
        this.showNotification(result.message || 'Invalid password', 'error');
        document.getElementById('adminPassword').value = '';
      }
    } catch (error) {
      console.error('Error authenticating with backend:', error);
      this.showNotification('Authentication failed', 'error');
      document.getElementById('adminPassword').value = '';
    }
  }

  toggleAdminMode() {
    if (!this.adminMode) {
      this.openModal('adminModal');
      return;
    }

    const deleteButtons = document.querySelectorAll('.delete-btn');
    const appCards = document.querySelectorAll('.card');
    
    if (this.adminMode) {
      deleteButtons.forEach(btn => btn.classList.remove('hidden'));
      appCards.forEach(card => {
        card.classList.add('border-red-500', 'bg-gray-750');
      });
    } else {
      deleteButtons.forEach(btn => btn.classList.add('hidden'));
      appCards.forEach(card => {
        card.classList.remove('border-red-500', 'bg-gray-750');
      });
    }
  }

  async deleteApp(appId, appName) {
    if (!this.adminMode) return;
    
    if (confirm(`Are you sure you want to delete "${appName}"?`)) {
      try {
        const response = await fetch(`/webapps/${appId}`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Content-Type': 'application/json'
          },
          credentials: 'same-origin'
        });

        if (response.ok) {
          // Remove the app card from DOM instead of reloading
          const appCard = document.querySelector(`[data-app-id="${appId}"]`);
          if (appCard) {
            // Add fade out animation
            appCard.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out';
            appCard.style.opacity = '0';
            appCard.style.transform = 'scale(0.8)';
            
            // Remove from DOM after animation
            setTimeout(() => {
              appCard.remove();
              this.updateResultsCounter();
            }, 300);
          }
          
          this.showNotification(`"${appName}" deleted successfully`, 'success');
        } else {
          throw new Error('Delete failed');
        }
      } catch (error) {
        console.error('Error deleting app:', error);
        this.showNotification('Failed to delete app', 'error');
      }
    }
  }

  // Update results counter after deletion
  updateResultsCounter() {
    const resultsCounter = document.getElementById('results-counter');
    if (resultsCounter) {
      const visibleCards = document.querySelectorAll('.card:not([style*="display: none"])');
      resultsCounter.textContent = `${visibleCards.length} apps found`;
    }
  }

  // Notification System
  showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 px-6 py-3 rounded-lg text-white font-semibold z-50 transition-all duration-300 ${
      type === 'success' ? 'bg-green-600' : 
      type === 'error' ? 'bg-red-600' : 
      'bg-blue-600'
    }`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.style.opacity = '0';
      notification.style.transform = 'translateX(100%)';
      setTimeout(() => notification.remove(), 300);
    }, 3000);
  }
}

// Global functions for HTML onclick handlers
let omarchyApp;

document.addEventListener('DOMContentLoaded', () => {
  omarchyApp = new OmarchyApp();
});

// Global functions for backward compatibility
function showAppDetailsModal(card) {
  omarchyApp?.showAppDetailsModal(card);
}

function openModal() {
  omarchyApp?.openModal('addAppModal');
}

function closeModal() {
  omarchyApp?.closeModal('addAppModal');
}

function openHelpModal() {
  omarchyApp?.openModal('helpModal');
}

function closeHelpModal() {
  omarchyApp?.closeModal('helpModal');
}

function openAdminModal() {
  omarchyApp?.openModal('adminModal');
}

function closeAdminModal() {
  omarchyApp?.closeModal('adminModal');
}

function closeAppDetailsModal() {
  omarchyApp?.closeModal('appDetailsModal');
}

function authenticateAdmin() {
  omarchyApp?.authenticateAdmin();
}

function deleteApp(appId, appName) {
  omarchyApp?.deleteApp(appId, appName);
}
