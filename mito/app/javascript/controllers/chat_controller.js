import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'messagesContainer',
    'form',
    'textarea',
    'submitButton',
    'loadingIndicator',
  ];

  static values = {
    chatId: String,
    isAnonymous: Boolean,
    currentUserEmail: String,
    isAdmin: Boolean,
  };

  connect() {
    console.log('Chat controller connected', {
      chatId: this.chatIdValue,
      isAnonymous: this.isAnonymousValue,
      isAdmin: this.isAdminValue,
    });
    this.scrollToBottom();
    this.setupKeyboardShortcuts();
  }

  setupKeyboardShortcuts() {
    if (this.hasTextareaTarget) {
      this.textareaTarget.addEventListener(
        'keydown',
        this.handleKeydown.bind(this),
      );
    }
  }

  handleKeydown(event) {
    // Enter to submit (without Shift), Shift+Enter for new line
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.submitMessage();
    }
  }

  async submitMessage(event) {
    if (event) event.preventDefault();

    const content = this.textareaTarget.value.trim();
    if (!content) return;

    // Add user message to UI immediately (optimistic update)
    this.addUserMessageToUI(content);

    // Show loading state after user message
    this.showLoadingState();

    // Clear the form immediately for better UX
    this.textareaTarget.value = '';
    this.scrollToBottom();

    try {
      // Submit message via AJAX
      const response = await this.sendMessageToServer(content);

      if (response.ok) {
        const data = await response.json();

        // Add assistant response(s) to UI
        if (data.comparison_data) {
          // Admin comparison view
          this.addComparisonMessageToUI(data.comparison_data);
        } else if (data.assistant_message) {
          // Regular assistant response
          this.addAssistantMessageToUI(data.assistant_message);
        }

        // Show signup invitation if needed
        if (data.show_signup_invitation) {
          this.addSignupInvitationToUI();
        }

        // Update chat title in sidebar if it's a new chat
        if (data.chat_title) {
          this.updateChatTitle(data.chat_title);
        }
      } else {
        // Handle server errors
        this.addErrorMessageToUI(
          'Nastala chyba pri odosielaní správy. Skúste to znovu.',
        );
      }
    } catch (error) {
      console.error('Error sending message:', error);
      this.addErrorMessageToUI(
        'Chyba siete. Skontrolujte pripojenie a skúste to znovu.',
      );

      // Re-add the user's message back to the textarea so they can retry
      this.textareaTarget.value = content;
    } finally {
      this.hideLoadingState();
      this.scrollToBottom();
    }
  }

  async sendMessageToServer(content) {
    const url = this.isAnonymousValue
      ? '/anonymous_messages'
      : `/chats/${this.chatIdValue}/messages`;
    const csrfToken = document.querySelector('[name="csrf-token"]').content;

    const body = this.isAnonymousValue
      ? { anonymous_message: { content: content } }
      : { message: { content: content } };

    return fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
    });
  }

  addUserMessageToUI(content) {
    const messageHtml = this.createUserMessageHTML(content);
    this.messagesContainerTarget.insertAdjacentHTML('beforeend', messageHtml);
  }

  addAssistantMessageToUI(messageData) {
    const messageHtml = this.createAssistantMessageHTML(
      messageData.content,
      messageData.sources || [],
    );
    this.messagesContainerTarget.insertAdjacentHTML('beforeend', messageHtml);
  }

  addComparisonMessageToUI(comparisonData) {
    const messageHtml = this.createComparisonMessageHTML(comparisonData);
    this.messagesContainerTarget.insertAdjacentHTML('beforeend', messageHtml);
  }

  addErrorMessageToUI(errorMessage) {
    const messageHtml = this.createErrorMessageHTML(errorMessage);
    this.messagesContainerTarget.insertAdjacentHTML('beforeend', messageHtml);
  }

  addSignupInvitationToUI() {
    if (this.isAnonymousValue) {
      const invitationHtml = this.createSignupInvitationHTML();
      this.messagesContainerTarget.insertAdjacentHTML(
        'beforeend',
        invitationHtml,
      );
    }
  }

  createUserMessageHTML(content) {
    const timestamp = this.formatTimestamp(new Date());
    return `
      <div class="flex justify-end">
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-emerald-600 text-white">
          <p class="text-sm">${this.escapeHtml(content)}</p>
          <p class="text-xs text-emerald-100 mt-1">${timestamp}</p>
        </div>
      </div>
    `;
  }

  createAssistantMessageHTML(content, sources = []) {
    const timestamp = this.formatTimestamp(new Date());

    // Create sources HTML if sources exist
    const sourcesHtml =
      sources && sources.length > 0
        ? `
      <div class="mt-3 pt-3 border-t border-gray-100">
        <p class="text-xs font-medium text-gray-600 mb-2">Zdroje:</p>
        <div class="space-y-1">
          ${sources
            .slice(0, 3)
            .map(
              (source) => `
            <div class="text-xs">
              • ${source.url ? `<a href="${this.escapeHtml(source.url)}" target="_blank" class="text-blue-600 hover:text-blue-800 hover:underline">${this.escapeHtml(source.title)}</a>` : `<span class="text-gray-500">${this.escapeHtml(source.title)}</span>`}${this.isAdminValue ? ` <span class="text-gray-400">(${source.relevance_score ? source.relevance_score.toFixed(1) : '0.0'})</span>` : ''}
            </div>
          `,
            )
            .join('')}
        </div>
      </div>
    `
        : '';

    return `
      <div class="flex justify-start">
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-white border border-gray-200 text-gray-900">
          <div class="flex items-center mb-1">
            <span class="text-lg mr-2">🧬</span>
            <span class="text-xs font-medium text-gray-600">Miťo</span>
          </div>
          <div class="text-sm">${this.formatAssistantContent(content)}</div>
          ${sourcesHtml}
          <p class="text-xs text-gray-500 mt-1">${timestamp}</p>
        </div>
      </div>
    `;
  }

  createComparisonMessageHTML(comparisonData) {
    const timestamp = this.formatTimestamp(new Date());
    return `
      <div class="comparison-container mb-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          ${comparisonData.responses
            .map(
              (response) => `
            <div class="comparison-variant border border-gray-200 rounded-lg p-4">
              <div class="bg-emerald-50 px-3 py-2 rounded-t-lg border-b border-emerald-200">
                <div class="flex items-center">
                  <span class="text-lg mr-2">🧬</span>
                  <span class="font-medium text-emerald-800">Miťo - ${response.variant_name || 'Unknown'}</span>
                </div>
              </div>
              <div class="p-3">
                <div class="text-sm text-gray-800">${this.formatAssistantContent(response.response)}</div>
                ${
                  response.sources && response.sources.length > 0
                    ? `
                  <div class="mt-3 pt-3 border-t border-gray-100">
                    <p class="text-xs font-medium text-gray-600 mb-2">Zdroje:</p>
                    <div class="space-y-1">
                      ${response.sources
                        .slice(0, 3)
                        .map(
                          (source) => `
                        <div class="text-xs">
                          • ${source.url ? `<a href="${this.escapeHtml(source.url)}" target="_blank" class="text-blue-600 hover:text-blue-800 hover:underline">${this.escapeHtml(source.title)}</a>` : `<span class="text-gray-500">${this.escapeHtml(source.title)}</span>`}${this.isAdminValue ? ` <span class="text-gray-400">(${source.relevance_score ? source.relevance_score.toFixed(1) : '0.0'})</span>` : ''}
                        </div>
                      `,
                        )
                        .join('')}
                    </div>
                  </div>
                `
                    : ''
                }
                <p class="text-xs text-gray-500 mt-2">${timestamp}</p>
              </div>
            </div>
          `,
            )
            .join('')}
        </div>
      </div>
    `;
  }

  createErrorMessageHTML(errorMessage) {
    const timestamp = this.formatTimestamp(new Date());
    return `
      <div class="flex justify-center">
        <div class="max-w-md px-4 py-2 rounded-lg bg-red-50 border border-red-200 text-red-800">
          <div class="flex items-center mb-1">
            <span class="text-lg mr-2">⚠️</span>
            <span class="text-xs font-medium">Chyba</span>
          </div>
          <p class="text-sm">${this.escapeHtml(errorMessage)}</p>
          <p class="text-xs text-red-600 mt-1">${timestamp}</p>
        </div>
      </div>
    `;
  }

  createSignupInvitationHTML() {
    return `
      <div class="flex justify-center my-6" id="signup_invitation">
        <div class="max-w-md bg-gradient-to-r from-emerald-50 to-emerald-100 border border-emerald-200 rounded-lg p-4 shadow-sm">
          <div class="text-center">
            <div class="text-2xl mb-2">✨</div>
            <h3 class="text-lg font-semibold text-emerald-800 mb-2">Páči sa vám Miťo?</h3>
            <p class="text-sm text-emerald-700 mb-4">
              Zaregistrujte sa a uložte si históriu konverzácií, aby ste sa k nim mohli vrátiť kedykoľvek.
            </p>
            <div class="flex space-x-2 justify-center">
              <a href="/users/sign_up" class="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors">
                Registrovať sa
              </a>
              <a href="/users/sign_in" class="bg-white hover:bg-gray-50 text-emerald-600 border border-emerald-600 px-4 py-2 rounded-md text-sm font-medium transition-colors">
                Prihlásiť sa
              </a>
            </div>
            <p class="text-xs text-emerald-600 mt-2">
              Môžete pokračovať aj bez registrácie
            </p>
          </div>
        </div>
      </div>
    `;
  }

  showLoadingState() {
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.innerHTML = `
      <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Premýšľam...
    `;

    // Add loading indicator to messages
    const loadingHtml = this.createLoadingIndicatorHTML();
    this.messagesContainerTarget.insertAdjacentHTML('beforeend', loadingHtml);
  }

  hideLoadingState() {
    this.submitButtonTarget.disabled = false;
    this.submitButtonTarget.innerHTML = 'Odoslať';

    // Remove loading indicator
    const loadingIndicator =
      this.messagesContainerTarget.querySelector('.loading-indicator');
    if (loadingIndicator) {
      loadingIndicator.remove();
    }
  }

  createLoadingIndicatorHTML() {
    return `
      <div class="loading-indicator flex justify-start">
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-gray-100 text-gray-800">
          <div class="flex items-center mb-1">
            <span class="text-lg mr-2">🧬</span>
            <span class="text-xs font-medium text-gray-600">Miťo</span>
          </div>
          <div class="flex items-center space-x-1">
            <div class="flex space-x-1">
              <div class="w-2 h-2 bg-gray-400 rounded-full loading-dot"></div>
              <div class="w-2 h-2 bg-gray-400 rounded-full loading-dot"></div>
              <div class="w-2 h-2 bg-gray-400 rounded-full loading-dot"></div>
            </div>
            <span class="text-xs text-gray-500 ml-2">Premýšľam...</span>
          </div>
        </div>
      </div>
    `;
  }

  scrollToBottom() {
    if (this.hasMessagesContainerTarget) {
      this.messagesContainerTarget.scrollTop =
        this.messagesContainerTarget.scrollHeight;
    }
  }

  updateChatTitle(newTitle) {
    // Update sidebar chat title if it exists
    const currentChatLink = document.querySelector(
      '.bg-emerald-50.border-r-2.border-emerald-500',
    );
    if (currentChatLink) {
      const titleElement = currentChatLink.querySelector(
        '.text-sm.font-medium',
      );
      if (titleElement) {
        titleElement.textContent = newTitle;
      }
    }
  }

  formatTimestamp(date) {
    return date.toLocaleTimeString('sk-SK', {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatAssistantContent(content) {
    // Basic markdown-like formatting with error handling
    if (!content || typeof content !== 'string') {
      console.warn('formatAssistantContent received invalid content:', content);
      return content || '';
    }

    return content
      .replace(/\n/g, '<br>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>');
  }

  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;',
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }
}
