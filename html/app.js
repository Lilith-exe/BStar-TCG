const app = document.getElementById('app');

// Viewer refs
const viewerWrap = document.getElementById('viewerWrap');
const cardImage = document.getElementById('cardImage');
const closeBtn = document.getElementById('closeBtn');

// Deck box refs
const deckboxWrap = document.getElementById('deckboxWrap');
const deckboxCloseBtn = document.getElementById('deckboxCloseBtn');
const playerCardsEl = document.getElementById('playerCards');
const deckBoxCardsEl = document.getElementById('deckBoxCards');

// Deck builder refs
const deckBuilderWrap = document.getElementById('deckBuilderWrap');
const builderPoolCardsEl = document.getElementById('builderPoolCards');
const builderDeckCardsEl = document.getElementById('builderDeckCards');
const savedDeckListEl = document.getElementById('savedDeckList');
const builderPreviewImage = document.getElementById('builderPreviewImage');
const builderPreviewName = document.getElementById('builderPreviewName');
const builderPreviewMeta = document.getElementById('builderPreviewMeta');
const currentDeckNameEl = document.getElementById('currentDeckName');
const currentDeckCountEl = document.getElementById('currentDeckCount');
const deckSearchInput = document.getElementById('deckSearchInput');
const newDeckBtn = document.getElementById('newDeckBtn');
const saveDeckBtn = document.getElementById('saveDeckBtn');
const deleteDeckBtn = document.getElementById('deleteDeckBtn');
const closeDeckBuilderBtn = document.getElementById('closeDeckBuilderBtn');

// Deck hub refs
const deckHubWrap = document.getElementById('deckHubWrap');
const deckHubTitleEl = deckHubWrap.querySelector('.deckhub-title');
const deckHubListEl = document.getElementById('deckHubList');
const deckHubCloseBtn = document.getElementById('deckHubCloseBtn');
const deckHubNewBtn = document.getElementById('deckHubNewBtn');
const deckHubEditBtn = document.getElementById('deckHubEditBtn');
const deckHubDeleteBtn = document.getElementById('deckHubDeleteBtn');
const deckHubCardsBtn = document.getElementById('deckHubCardsBtn');

// Modal refs
const uiModalWrap = document.getElementById('uiModalWrap');
const uiModalTitle = document.getElementById('uiModalTitle');
const uiModalText = document.getElementById('uiModalText');
const uiModalInput = document.getElementById('uiModalInput');
const uiModalCancelBtn = document.getElementById('uiModalCancelBtn');
const uiModalConfirmBtn = document.getElementById('uiModalConfirmBtn');
const coinFlipWrap = document.getElementById('coinFlipWrap');
const coinDisc = document.getElementById('coinDisc');
const coinFlipTitle = document.getElementById('coinFlipTitle');
const coinFlipText = document.getElementById('coinFlipText');
const coinChoiceActions = document.getElementById('coinChoiceActions');
const turnChoiceActions = document.getElementById('turnChoiceActions');
const coinHeadsBtn = document.getElementById('coinHeadsBtn');
const coinTailsBtn = document.getElementById('coinTailsBtn');
const goFirstBtn = document.getElementById('goFirstBtn');
const goSecondBtn = document.getElementById('goSecondBtn');

// Duel refs
const duelWrap = document.getElementById('duelWrap');
const duelTurnText = document.getElementById('duelTurnText');
const duelPhaseText = document.getElementById('duelPhaseText');
const duelStatusText = document.getElementById('duelStatusText');
const duelOpponentDeckCount = document.getElementById('duelOpponentDeckCount');
const duelOpponentHandCount = document.getElementById('duelOpponentHandCount');
const duelOpponentGraveCount = document.getElementById('duelOpponentGraveCount');
const duelSelfDeckCount = document.getElementById('duelSelfDeckCount');
const duelSelfGraveCount = document.getElementById('duelSelfGraveCount');
const duelOpponentFighterZones = document.getElementById('duelOpponentFighterZones');
const duelSelfFighterZones = document.getElementById('duelSelfFighterZones');
const duelHandCards = document.getElementById('duelHandCards');
const duelAdvancePhaseBtn = document.getElementById('duelAdvancePhaseBtn');
const duelEndTurnBtn = document.getElementById('duelEndTurnBtn');
const duelCloseBtn = document.getElementById('duelCloseBtn');
const duelSpawnOppBtn = document.getElementById('duelSpawnOppBtn');
const duelSpawnMeBtn = document.getElementById('duelSpawnMeBtn');
const duelSelfLP = document.getElementById('duelSelfLP');
const duelOpponentLP = document.getElementById('duelOpponentLP');
const tableDuelWrap = document.getElementById('tableDuelWrap');
const tableBoard = document.getElementById('tableBoard');
const tableOpponentLP = document.getElementById('tableOpponentLP');
const tableSelfLP = document.getElementById('tableSelfLP');
const tablePhaseBadge = document.getElementById('tablePhaseBadge');
const tableOpponentDeckCount = document.getElementById('tableOpponentDeckCount');
const tableSelfDeckCount = document.getElementById('tableSelfDeckCount');
const tableOpponentHandBacks = document.getElementById('tableOpponentHandBacks');
const tableOpponentCemeterySlot = document.getElementById('tableOpponentCemeterySlot');
const tableSelfCemeterySlot = document.getElementById('tableSelfCemeterySlot');
const tableOpponentCemeteryCount = document.getElementById('tableOpponentCemeteryCount');
const tableSelfCemeteryCount = document.getElementById('tableSelfCemeteryCount');
const tableOpponentCemeteryImage = document.getElementById('tableOpponentCemeteryImage');
const tableSelfCemeteryImage = document.getElementById('tableSelfCemeteryImage');
const tableOpponentDeckSlot = document.getElementById('tableOpponentDeckSlot');
const tableSelfDeckSlot = document.getElementById('tableSelfDeckSlot');
const tableOpponentZones = document.getElementById('tableOpponentZones');
const tableSelfZones = document.getElementById('tableSelfZones');
const tableHandRow = document.getElementById('tableHandRow');
const tableDrawPrompt = document.getElementById('tableDrawPrompt');
const tablePreviewPanel = document.getElementById('tablePreviewPanel');
const tablePreviewImage = document.getElementById('tablePreviewImage');
const tablePreviewName = document.getElementById('tablePreviewName');
const tablePreviewMeta = document.getElementById('tablePreviewMeta');
const tablePreviewStats = document.getElementById('tablePreviewStats');
const tablePreviewEffect = document.getElementById('tablePreviewEffect');
const tableSelfGraveBtn = document.getElementById('tableSelfGraveBtn');
const tableOpponentGraveBtn = document.getElementById('tableOpponentGraveBtn');
const tableGravePanel = document.getElementById('tableGravePanel');
const tableGraveList = document.getElementById('tableGraveList');
const tableNextPhaseBtn = document.getElementById('tableNextPhaseBtn');
const tableEndTurnBtn = document.getElementById('tableEndTurnBtn');
const tableCloseBtn = document.getElementById('tableCloseBtn');
const tableResultOverlay = document.getElementById('tableResultOverlay');
const tableResultTitle = document.getElementById('tableResultTitle');
const tableResultReason = document.getElementById('tableResultReason');
const tableResultMeta = document.getElementById('tableResultMeta');
const tableResultCloseBtn = document.getElementById('tableResultCloseBtn');
const duelResultOverlay = document.getElementById('duelResultOverlay');
const duelResultTitle = document.getElementById('duelResultTitle');
const duelResultReason = document.getElementById('duelResultReason');
const duelResultMeta = document.getElementById('duelResultMeta');
const duelResultCloseBtn = document.getElementById('duelResultCloseBtn');

// General state
let activeModalAction = null;

let isZoomed = false;
let targetRotateX = 0;
let targetRotateY = 0;
let currentRotateX = 0;
let currentRotateY = 0;
let animationFrame = null;

let currentDeckBoxId = null;
let currentPlayerCards = {};
let currentStoredCards = {};

let viewerOpenedFromDeckBox = false;
let viewerOpenedFromDeckBuilder = false;

let currentDecks = [];
let selectedDeck = null;
let builderOwnedCards = {};
let builderSearchTerm = '';
let selectedHubDeckId = null;
let deckHubMode = 'manage';
let pendingTableDuelId = null;
let pendingCoinDuelId = null;
let pendingCoinChoice = null;
let coinResultTimer = null;
let coinFlipStartedAt = 0;

let currentDuelState = null;
let selectedHandCardUid = null;
let selectedAttackerZoneIndex = null;
let duelTableMode = false;
let tablePreviewCard = null;
let openTableGraveSide = null;
let tableDrawAnimating = false;
let tableZoneSnapshot = null;
let tableGraveSnapshot = null;

let builderFilters = {
  type: 'all',
  rarity: 'all',
  minAtk: '',
  maxAtk: '',
  minDef: '',
  maxDef: '',
  minSpd: '',
  maxSpd: '',
  minLevel: '',
  maxLevel: ''
};

// ---------- Helpers ----------

function clone(obj) {
  return JSON.parse(JSON.stringify(obj));
}

function getThumbImagePath(card) {
  const file = card?.inventoryImage || 'default.png';
  return `nui://bstar_cards/html/images/cards/thumbs/${file}`;
}

function getFullImagePath(card) {
  const file = card?.inventoryImage || 'default.png';
  return `nui://bstar_cards/html/images/cards/${file}`;
}

function setCardThumbImage(img, card) {
  img.src = getThumbImagePath(card);
  img.onerror = () => {
    img.onerror = null;
    img.src = getCardImagePathFromPayload(card);
  };
}

function getBaseScale() {
  return isZoomed ? 1.04 : 1.0;
}

function ensureAnimationLoop() {
  if (!animationFrame) {
    animationFrame = requestAnimationFrame(updateCardTransform);
  }
}

function resetTilt() {
  targetRotateX = 0;
  targetRotateY = 0;
}

function hideAll() {
  clearCoinResultTimer();
  app.classList.add('hidden');
  viewerWrap.classList.add('hidden');
  deckboxWrap.classList.add('hidden');
  deckBuilderWrap.classList.add('hidden');
  deckHubWrap.classList.add('hidden');
  uiModalWrap.classList.add('hidden');
  coinFlipWrap.classList.add('hidden');
  duelWrap.classList.add('hidden');
  tableDuelWrap.classList.add('hidden');

  cardImage.src = '';
  cardImage.classList.remove('zoomed');
  isZoomed = false;
  resetTilt();
}

function normalizeDeck(deck) {
  if (!deck) return deck;

  if (!deck.deck_data || typeof deck.deck_data !== 'object' || Array.isArray(deck.deck_data)) {
    deck.deck_data = { cards: {} };
  }

  if (!deck.deck_data.cards || typeof deck.deck_data.cards !== 'object' || Array.isArray(deck.deck_data.cards)) {
    deck.deck_data.cards = {};
  }

  return deck;
}

function syncSelectedDeckIntoCache() {
  if (!selectedDeck) return;

  const index = currentDecks.findIndex(d => d.id === selectedDeck.id);
  if (index !== -1) {
    currentDecks[index] = clone(selectedDeck);
  }
}

function getDeckCardCount(deck) {
  if (!deck || !deck.deck_data || !deck.deck_data.cards) return 0;
  return Object.values(deck.deck_data.cards).reduce((sum, val) => sum + val, 0);
}

function getSelectedDeckCardCount(cardId) {
  if (!selectedDeck || !selectedDeck.deck_data || !selectedDeck.deck_data.cards) return 0;
  return selectedDeck.deck_data.cards[cardId] || 0;
}

function getMaxCopiesPerCard() {
  return 3;
}

function getDeckValidationIssues(deck, checkOwnedCards = true) {
  const issues = [];

  if (!deck || !deck.deck_data || !deck.deck_data.cards) {
    return ['No deck data'];
  }

  const count = getDeckCardCount(deck);
  if (count < 30) issues.push('Too small');
  if (count > 50) issues.push('Too large');

  for (const cardId in deck.deck_data.cards) {
    const copies = Number(deck.deck_data.cards[cardId]) || 0;
    const owned = builderOwnedCards[cardId]?.amount || 0;

    if (copies > getMaxCopiesPerCard()) {
      issues.push('Too many copies');
    }

    if (checkOwnedCards && copies > owned) {
      issues.push('Missing cards');
    }
  }

  return [...new Set(issues)];
}

function isDeckValid(deck, checkOwnedCards = true) {
  return getDeckValidationIssues(deck, checkOwnedCards).length === 0;
}

function isOwnedCardDimmed(cardId) {
  const owned = builderOwnedCards[cardId]?.amount || 0;
  const inDeck = getSelectedDeckCardCount(cardId);
  const maxCopies = getMaxCopiesPerCard();

  return inDeck >= owned || inDeck >= maxCopies;
}

function isDeckCardInvalid(cardId) {
  const owned = builderOwnedCards[cardId]?.amount || 0;
  const inDeck = getSelectedDeckCardCount(cardId);
  return inDeck > owned || inDeck > getMaxCopiesPerCard();
}

// ---------- Modal ----------

function openModal({ title, text, showInput = false, inputValue = '', confirmText = 'Confirm', onConfirm = null }) {
  activeModalAction = onConfirm || null;

  uiModalTitle.textContent = title || 'Confirm';
  uiModalText.textContent = text || '';
  uiModalConfirmBtn.textContent = confirmText;

  if (showInput) {
    uiModalInput.classList.remove('hidden');
    uiModalInput.value = inputValue || '';
    setTimeout(() => uiModalInput.focus(), 0);
  } else {
    uiModalInput.classList.add('hidden');
    uiModalInput.value = '';
  }

  uiModalWrap.classList.remove('hidden');
}

function closeModal() {
  uiModalWrap.classList.add('hidden');
  uiModalInput.classList.add('hidden');
  uiModalInput.value = '';
  activeModalAction = null;
}

function clearCoinResultTimer() {
  if (coinResultTimer) {
    clearTimeout(coinResultTimer);
    coinResultTimer = null;
  }
}

function setCoinChoiceButtonsDisabled(disabled) {
  coinHeadsBtn.disabled = disabled;
  coinTailsBtn.disabled = disabled;
}

function resetCoinDisc() {
  clearCoinResultTimer();
  pendingCoinChoice = null;
  coinFlipStartedAt = 0;
  coinDisc.dataset.face = 'CALL';
  coinDisc.textContent = '';
  coinDisc.classList.remove('called-heads', 'called-tails', 'flipping', 'resolving', 'heads', 'tails');
  setCoinChoiceButtonsDisabled(false);
}

function openCoinFlip(data) {
  hideAll();
  pendingCoinDuelId = data?.duelId || null;

  app.classList.remove('hidden');
  coinFlipWrap.classList.remove('hidden');
  resetCoinDisc();
  coinFlipTitle.textContent = 'Call the Toss';
  coinFlipText.textContent = 'Choose heads or tails.';
  coinChoiceActions.classList.remove('hidden');
  turnChoiceActions.classList.add('hidden');
}

function sendCoinChoice(choice) {
  if (!pendingCoinDuelId) return;

  clearCoinResultTimer();
  pendingCoinChoice = choice;
  coinFlipStartedAt = performance.now();
  coinDisc.dataset.face = choice === 'heads' ? 'HEADS' : 'TAILS';
  coinDisc.textContent = '';
  coinDisc.classList.remove('heads', 'tails', 'resolving', 'called-heads', 'called-tails');
  coinDisc.classList.add(`called-${choice}`, 'flipping');
  setCoinChoiceButtonsDisabled(true);
  coinChoiceActions.classList.add('hidden');
  coinFlipTitle.textContent = 'Flipping...';
  coinFlipText.textContent = `You called ${choice}.`;

  fetch(`https://${GetParentResourceName()}/duelChooseCoin`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ choice })
  });
}

function showCoinFlipResult(result) {
  if (!result) return;

  coinChoiceActions.classList.add('hidden');
  turnChoiceActions.classList.add('hidden');
  coinFlipTitle.textContent = 'Flipping...';
  coinFlipText.textContent = pendingCoinChoice
    ? `You called ${pendingCoinChoice}.`
    : 'The coin is in the air.';

  clearCoinResultTimer();
  const elapsed = coinFlipStartedAt ? performance.now() - coinFlipStartedAt : 0;
  const revealDelay = Math.max(0, 1280 - elapsed);
  coinResultTimer = setTimeout(() => {
    coinResultTimer = null;
    const resultFace = result.result === 'heads' ? 'HEADS' : 'TAILS';

    coinDisc.dataset.face = resultFace;
    coinDisc.textContent = '';
    coinDisc.classList.remove('called-heads', 'called-tails', 'flipping', 'resolving', 'heads', 'tails');
    void coinDisc.offsetWidth;
    coinDisc.classList.add('resolving', result.result);

    coinFlipTitle.textContent = result.playerWon ? 'You won the toss' : 'Opponent won the toss';
    coinFlipText.textContent = result.playerWon
      ? 'Choose who takes the first turn.'
      : 'Opponent chooses to go first.';

    turnChoiceActions.classList.toggle('hidden', !result.canChooseTurnOrder);
  }, revealDelay);
}

function chooseTurnOrder(choice) {
  if (!pendingCoinDuelId) return;

  turnChoiceActions.classList.add('hidden');
  coinFlipText.textContent = choice === 'first' ? 'You chose to go first.' : 'You chose to go second.';

  fetch(`https://${GetParentResourceName()}/duelChooseTurnOrder`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ choice })
  });
}

// ---------- Viewer ----------

function updateCardTransform() {
  const smoothing = 0.12;

  currentRotateX += (targetRotateX - currentRotateX) * smoothing;
  currentRotateY += (targetRotateY - currentRotateY) * smoothing;

  const scale = getBaseScale();
  cardImage.style.transform =
    `perspective(1200px) rotateX(${currentRotateX}deg) rotateY(${currentRotateY}deg) scale(${scale})`;

  animationFrame = requestAnimationFrame(updateCardTransform);
}

function openFullViewer(card, fromDeckBox = false, fromDeckBuilder = false) {
  viewerOpenedFromDeckBox = fromDeckBox;
  viewerOpenedFromDeckBuilder = fromDeckBuilder;

  viewerWrap.classList.remove('hidden');
  cardImage.src = getFullImagePath(card);
  cardImage.classList.remove('zoomed');
  isZoomed = false;
  currentRotateX = 0;
  currentRotateY = 0;
  resetTilt();
  app.classList.remove('hidden');
  ensureAnimationLoop();
}

function closeFullViewer(notifyLua = true) {
  viewerWrap.classList.add('hidden');
  cardImage.src = '';
  cardImage.classList.remove('zoomed');
  isZoomed = false;
  resetTilt();

  const returningToDeckBox = viewerOpenedFromDeckBox;
  const returningToDeckBuilder = viewerOpenedFromDeckBuilder;

  viewerOpenedFromDeckBox = false;
  viewerOpenedFromDeckBuilder = false;

  if (returningToDeckBox || returningToDeckBuilder || currentDuelState) {
    app.classList.remove('hidden');
    return;
  }

  app.classList.add('hidden');

  if (notifyLua) {
    fetch(`https://${GetParentResourceName()}/closeCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  }
}

function requestDuelSurrender() {
  if (!currentDuelState || currentDuelState.status !== 'active') {
    closeDuelUi();
    return;
  }

  openModal({
    title: 'Surrender Duel',
    text: 'Surrender this duel and take the loss?',
    showInput: false,
    confirmText: 'Surrender',
    onConfirm: () => {
      fetch(`https://${GetParentResourceName()}/duelSurrender`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
    }
  });
}

// ---------- Deck Box Storage Screen ----------

function openDeckBox(data) {
  hideAll();

  currentDeckBoxId = data.deckBoxId;
  currentPlayerCards = data.playerCards || {};
  currentStoredCards = data.storedCards || {};

  app.classList.remove('hidden');
  deckboxWrap.classList.remove('hidden');
  renderDeckBox();
}

function resolveCardData(card) {
  if (!card) return null;

  // If the full data is already on the object, just use it
  if (card.effectText || card.attack || card.defense || card.speed || card.rarity || card.type) {
    return card;
  }

  // Try pulling full data from a global card table if your UI receives one later
  if (window.BSTAR_CARD_DEFS && card.cardId && window.BSTAR_CARD_DEFS[card.cardId]) {
    return {
      ...window.BSTAR_CARD_DEFS[card.cardId],
      ...card
    };
  }

  return card;
}

function renderDeckBox() {
  renderCardGrid(playerCardsEl, currentPlayerCards, 'player');
  renderCardGrid(deckBoxCardsEl, currentStoredCards, 'deckbox');
}

function renderCardGrid(container, cards, side) {
  container.innerHTML = '';

  const sortedIds = Object.keys(cards).sort();
  if (!sortedIds.length) return;

  for (const cardId of sortedIds) {
    const card = cards[cardId];

    const div = document.createElement('div');
    div.className = 'deckbox-card';
    div.dataset.cardId = cardId;
    div.dataset.from = side;

    const imageWrap = document.createElement('div');
    imageWrap.className = 'deckbox-card-image-wrap';

    const img = document.createElement('img');
    img.src = getThumbImagePath(card);
    img.loading = 'lazy';
    img.onerror = () => {
      img.onerror = null;
      img.src = getFullImagePath(card);
    };
    img.draggable = false;

    const count = document.createElement('div');
    count.className = 'deckbox-count';
    count.textContent = card.amount;

    const name = document.createElement('div');
    name.className = 'deckbox-card-name';
    name.textContent = card.name || card.cardId;

    imageWrap.appendChild(img);
    imageWrap.appendChild(count);
    div.appendChild(imageWrap);
    div.appendChild(name);

    div.addEventListener('mousedown', (e) => {
      e.preventDefault();
      e.stopPropagation();

      if (e.button === 0) {
        openFullViewer(card, true, false);
        return;
      }

      if (e.button === 2) {
        if (side === 'player') {
          fetch(`https://${GetParentResourceName()}/storeCard`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              deckBoxId: currentDeckBoxId,
              cardId
            })
          }).then(() => {
            setTimeout(refreshDeckBox, 120);
          });
        } else if (side === 'deckbox') {
          fetch(`https://${GetParentResourceName()}/withdrawCard`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              deckBoxId: currentDeckBoxId,
              cardId
            })
          }).then(() => {
            setTimeout(refreshDeckBox, 120);
          });
        }
      }
    });

    container.appendChild(div);
  }
}

function refreshDeckBox() {
  if (!currentDeckBoxId) return;

  fetch(`https://${GetParentResourceName()}/refreshDeckBox`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      currentPlayerCards = data.playerCards || {};
      currentStoredCards = data.storedCards || {};
      renderDeckBox();
    });
}

// ---------- Deck Hub ----------

function openDeckHub(data) {
  hideAll();

  currentDeckBoxId = data.deckBoxId;
  deckHubMode = data.mode || 'manage';
  pendingTableDuelId = data.tableId || null;
  window.BSTAR_CARD_DEFS = data.cardCatalog || window.BSTAR_CARD_DEFS || {};
  builderOwnedCards = data.storedCards || {};
  currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));
  const firstLegalDeck = currentDecks.find(deck => deck.isValid !== false && isDeckValid(deck));
  selectedHubDeckId = firstLegalDeck?.id || (currentDecks[0]?.id || null);

  app.classList.remove('hidden');
  deckHubWrap.classList.remove('hidden');
  renderDeckHub();
}

function renderDeckHub() {
  deckHubListEl.innerHTML = '';

  if (deckHubTitleEl) {
    deckHubTitleEl.textContent = deckHubMode === 'tableSelect' ? 'Choose Duel Deck' : 'Deck Box';
  }

  const selectingForTable = deckHubMode === 'tableSelect';
  deckHubNewBtn.classList.toggle('hidden', selectingForTable);
  deckHubDeleteBtn.classList.toggle('hidden', selectingForTable);
  deckHubCardsBtn.classList.toggle('hidden', selectingForTable);
  deckHubEditBtn.textContent = selectingForTable ? 'Start Duel' : 'Edit';

  if (!currentDecks.length) {
    deckHubListEl.innerHTML = '<div style="opacity:.65;padding:12px;">No decks yet. Create one below.</div>';
    return;
  }

  currentDecks.forEach(deck => {
    const row = document.createElement('div');
    row.className = 'deckhub-row';

    const valid = deck.isValid === false ? false : isDeckValid(deck);
    const issues = deck.validationMessage
      ? [deck.validationMessage]
      : getDeckValidationIssues(deck);

    if (!valid) {
      row.classList.add('invalid');
    }

    if (deck.id === selectedHubDeckId) {
      row.classList.add('active');
    }

    const count = getDeckCardCount(deck);

    const top = document.createElement('div');
    top.className = 'deckhub-row-top';

    const name = document.createElement('div');
    name.className = 'deckhub-row-name';
    name.textContent = deck.name;

    const status = document.createElement('div');
    status.className = `deckhub-status ${valid ? 'valid' : 'invalid'}`;
    status.textContent = valid ? 'Legal' : 'Invalid';

    const meta = document.createElement('div');
    meta.className = 'deckhub-row-meta';

    meta.textContent = issues.length
      ? `${count} cards • ${issues.join(', ')}`
      : `${count} cards • Ready to duel`;

    top.appendChild(name);
    top.appendChild(status);

    row.appendChild(top);
    row.appendChild(meta);

    row.addEventListener('click', () => {
      selectedHubDeckId = deck.id;
      renderDeckHub();
    });

    row.addEventListener('dblclick', () => {
      selectedHubDeckId = deck.id;
      renderDeckHub();

      if (deckHubMode === 'tableSelect') {
        startSelectedTableDuelDeck();
      }
    });

    row.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      if (deckHubMode === 'tableSelect') return;

      selectedHubDeckId = deck.id;
      renderDeckHub();

      const targetDeck = getSelectedHubDeck();
      if (!targetDeck) return;

      openModal({
        title: 'Rename Deck',
        text: 'Enter a new name for this deck.',
        showInput: true,
        inputValue: targetDeck.name || '',
        confirmText: 'Rename',
        onConfirm: (value) => {
          const newName = value.trim();
          if (!newName) return;

          targetDeck.name = newName;

          fetch(`https://${GetParentResourceName()}/saveDeck`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              deckBoxId: currentDeckBoxId,
              deckId: targetDeck.id,
              deckName: targetDeck.name,
              deckData: targetDeck.deck_data
            })
          }).then(() => {
            setTimeout(refreshDeckHub, 150);
          });
        }
      });
    });

    deckHubListEl.appendChild(row);
  });
}

function getSelectedHubDeck() {
  return currentDecks.find(d => d.id === selectedHubDeckId) || null;
}

function startSelectedTableDuelDeck() {
  const deck = getSelectedHubDeck();
  if (!deck) return;

  const valid = deck.isValid === false ? false : isDeckValid(deck);
  if (!valid) {
    openModal({
      title: 'Invalid Deck',
      text: deck.validationMessage || getDeckValidationIssues(deck).join(', '),
      showInput: false,
      confirmText: 'OK'
    });
    return;
  }

  hideAll();

  fetch(`https://${GetParentResourceName()}/selectTableDuelDeck`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      tableId: pendingTableDuelId,
      deckId: deck.id
    })
  });

  deckHubMode = 'manage';
  pendingTableDuelId = null;
}

function refreshDeckHub() {
  if (!currentDeckBoxId) return;

  fetch(`https://${GetParentResourceName()}/refreshDeckBuilder`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      window.BSTAR_CARD_DEFS = data.cardCatalog || window.BSTAR_CARD_DEFS || {};
      builderOwnedCards = data.storedCards || {};
      currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));

      if (selectedHubDeckId) {
        const found = currentDecks.find(d => d.id === selectedHubDeckId);
        selectedHubDeckId = found ? found.id : (currentDecks[0]?.id || null);
      } else {
        selectedHubDeckId = currentDecks[0]?.id || null;
      }

      renderDeckHub();
    });
}

function parseCardStat(value) {
  if (value === null || value === undefined) return 0;
  if (typeof value === 'number') return value;

  const match = String(value).match(/-?\d+(\.\d+)?/);
  return match ? Number(match[0]) : 0;
}

function hookFilterInputs() {
  const bindings = [
    ['filterType', 'type'],
    ['filterRarity', 'rarity'],
    ['minAtk', 'minAtk'],
    ['maxAtk', 'maxAtk'],
    ['minDef', 'minDef'],
    ['maxDef', 'maxDef'],
    ['minSpd', 'minSpd'],
    ['maxSpd', 'maxSpd'],
    ['minLevel', 'minLevel'],
    ['maxLevel', 'maxLevel']
  ];

  const handler = () => {
    builderFilters[key] = el.value;
    console.log('[BStar] filter changed', key, el.value, builderFilters);
    renderBuilderPoolCards();
  };

  bindings.forEach(([id, key]) => {
    const el = document.getElementById(id);
    if (!el) return;

    if (el._filterHandler) {
      el.removeEventListener('input', el._filterHandler);
      el.removeEventListener('change', el._filterHandler);
    }

    const handler = () => {
      builderFilters[key] = el.value;
      renderBuilderPoolCards();
    };

    el.addEventListener('input', handler);
    el.addEventListener('change', handler);
    el._filterHandler = handler;
  });

  const clearBtn = document.getElementById('clearFiltersBtn');
  if (clearBtn) {
    if (clearBtn._clearHandler) {
      clearBtn.removeEventListener('click', clearBtn._clearHandler);
    }

    const clearHandler = () => {
      builderFilters = {
        type: 'all',
        rarity: 'all',
        minAtk: '',
        maxAtk: '',
        minDef: '',
        maxDef: '',
        minSpd: '',
        maxSpd: '',
        minLevel: '',
        maxLevel: ''
      };

      const filterType = document.getElementById('filterType');
      const filterRarity = document.getElementById('filterRarity');
      if (filterType) filterType.value = 'all';
      if (filterRarity) filterRarity.value = 'all';

      ['minAtk', 'maxAtk', 'minDef', 'maxDef', 'minSpd', 'maxSpd', 'minLevel', 'maxLevel'].forEach(id => {
        const input = document.getElementById(id);
        if (input) input.value = '';
      });

      renderBuilderPoolCards();
    };

    clearBtn.addEventListener('click', clearHandler);
    clearBtn._clearHandler = clearHandler;
  }
}

// ---------- Deck Builder ----------

function openDeckBuilder(data) {
  hideAll();

  currentDeckBoxId = data.deckBoxId;
  window.BSTAR_CARD_DEFS = data.cardCatalog || window.BSTAR_CARD_DEFS || {};
  builderOwnedCards = data.storedCards || {};
  currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));
  selectedDeck = currentDecks.length ? clone(currentDecks[0]) : null;
  builderSearchTerm = '';

  app.classList.remove('hidden');
  deckBuilderWrap.classList.remove('hidden');

  if (deckSearchInput) {
    deckSearchInput.value = '';
  }

  renderDeckBuilder();

  hookFilterInputs();
}

function renderDeckBuilder() {
  if (!savedDeckListEl || !builderPoolCardsEl || !builderDeckCardsEl) {
    return;
  }

  renderSavedDeckList();
  renderBuilderPoolCards();
  renderBuilderDeckCards();
  updateBuilderPreviewFromSelectedDeck();
  updateDeckHeader();
}

function renderSavedDeckList() {
  savedDeckListEl.innerHTML = '';

  currentDecks.forEach((deck) => {
    const row = document.createElement('div');
    row.className = 'saved-deck-row';

    if (!isDeckValid(deck)) {
      row.classList.add('invalid');
    }

    if (selectedDeck && selectedDeck.id === deck.id) {
      row.classList.add('active');
    }

    const count = getDeckCardCount(deck);
    const issues = getDeckValidationIssues(deck);
    row.textContent = issues.length
      ? `${deck.name} (${count}) - ${issues[0]}`
      : `${deck.name} (${count})`;

    row.addEventListener('click', () => {
      if (selectedDeck && selectedDeck.id === deck.id) return;
      selectedDeck = normalizeDeck(clone(deck));
      renderDeckBuilder();
    });

    savedDeckListEl.appendChild(row);
  });
}

function renderBuilderPoolCards() {
  builderPoolCardsEl.innerHTML = '';

  const sortedIds = Object.keys(builderOwnedCards)
    .filter((cardId) => {
      const card = builderOwnedCards[cardId];
      const resolved = resolveCardData(card);
      if (!resolved) return false;

      const name = (resolved.name || resolved.cardId || '').toLowerCase();
      if (!name.includes(builderSearchTerm.toLowerCase())) return false;

      const normalizedType = String(resolved.type || '').trim().toUpperCase();
      const normalizedRarity = String(resolved.rarity || '').trim().toUpperCase();

      if (builderFilters.type !== 'all' && !normalizedType.includes(builderFilters.type)) {
        return false;
      }

      if (builderFilters.rarity !== 'all' && !normalizedRarity.includes(builderFilters.rarity)) {
        return false;
      }

      const atk = parseCardStat(resolved.attack || resolved.atk);
      const def = parseCardStat(resolved.defense || resolved.def);
      const spd = parseCardStat(resolved.speed || resolved.spd);
      const level = parseCardStat(resolved.level);

      if (builderFilters.minAtk !== '' && atk < Number(builderFilters.minAtk)) return false;
      if (builderFilters.maxAtk !== '' && atk > Number(builderFilters.maxAtk)) return false;

      if (builderFilters.minDef !== '' && def < Number(builderFilters.minDef)) return false;
      if (builderFilters.maxDef !== '' && def > Number(builderFilters.maxDef)) return false;

      if (builderFilters.minSpd !== '' && spd < Number(builderFilters.minSpd)) return false;
      if (builderFilters.maxSpd !== '' && spd > Number(builderFilters.maxSpd)) return false;

      if (builderFilters.minLevel !== '' && level < Number(builderFilters.minLevel)) return false;
      if (builderFilters.maxLevel !== '' && level > Number(builderFilters.maxLevel)) return false;

      return true;
    })
    .sort();

  for (const cardId of sortedIds) {
    const card = builderOwnedCards[cardId];
    const deckCount = getSelectedDeckCardCount(cardId);
    const dimmed = isOwnedCardDimmed(cardId);

    const div = document.createElement('div');
    div.className = 'builder-card';
    if (dimmed) div.classList.add('dimmed');

    const imageWrap = document.createElement('div');
    imageWrap.className = 'builder-card-image-wrap';

    const img = document.createElement('img');
    img.src = getThumbImagePath(card);
    img.loading = 'lazy';
    img.onerror = () => {
      img.onerror = null;
      img.src = getFullImagePath(card);
    };

    const count = document.createElement('div');
    count.className = 'builder-card-count';
    count.textContent = `${deckCount}/${card.amount}`;

    const name = document.createElement('div');
    name.className = 'builder-card-name';
    name.textContent = card.name || card.cardId;

    imageWrap.appendChild(img);
    imageWrap.appendChild(count);
    div.appendChild(imageWrap);
    div.appendChild(name);

    div.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      setBuilderPreview(card);
      addCardToSelectedDeck(cardId);
    });

    div.addEventListener('click', () => {
      setBuilderPreview(card);
    });

    builderPoolCardsEl.appendChild(div);
  }
}

function renderBuilderDeckCards() {
  builderDeckCardsEl.innerHTML = '';

  if (!selectedDeck) return;

  normalizeDeck(selectedDeck);

  const cards = selectedDeck.deck_data.cards || {};
  const sortedIds = Object.keys(cards).sort();

  if (!sortedIds.length) {
    builderDeckCardsEl.innerHTML = '<div style="opacity:.6;padding:10px;">Right-click cards on the right to add them</div>';
    return;
  }

  for (const cardId of sortedIds) {
    const amount = cards[cardId] || 0;
    if (amount <= 0) continue;

    const ownedCard = resolveCardData(builderOwnedCards[cardId] || {
      cardId,
      amount: 0
    });

    const invalid = isDeckCardInvalid(cardId);

    for (let copyIndex = 0; copyIndex < amount; copyIndex++) {
      const div = document.createElement('div');
      div.className = 'builder-card';
      if (invalid) {
        div.classList.add('dimmed');
        div.classList.add('invalid');
      }

      const imageWrap = document.createElement('div');
      imageWrap.className = 'builder-card-image-wrap';

      const img = document.createElement('img');
      img.src = getThumbImagePath(ownedCard);
      img.loading = 'lazy';
      img.onerror = () => {
        img.onerror = null;
        img.src = getFullImagePath(ownedCard);
      };

      const name = document.createElement('div');
      name.className = 'builder-card-name';
      name.textContent = ownedCard.name || cardId;

      imageWrap.appendChild(img);
      div.appendChild(imageWrap);
      div.appendChild(name);

      div.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        setBuilderPreview(ownedCard);
        removeCardFromSelectedDeck(cardId);
      });

      div.addEventListener('click', () => {
        setBuilderPreview(ownedCard);
      });

      builderDeckCardsEl.appendChild(div);
    }
  }
}



function setBuilderPreview(card) {
  const resolved = resolveCardData(card);
  if (!resolved) return;

  builderPreviewName.textContent = resolved.name || resolved.cardId || 'Card Preview';
  builderPreviewImage.src = getFullImagePath(resolved);

  const type = resolved.type || '-';
  const rarity = resolved.rarity || '-';
  const level = resolved.level || '-';
  const atk = resolved.attack || resolved.atk || '-';
  const def = resolved.defense || resolved.def || '-';
  const spd = resolved.speed || resolved.spd || '-';

  builderPreviewMeta.innerHTML = `
    <div class="preview-stat-row">
      <span class="preview-stat-label">Type</span>
      <span class="preview-stat-value">${type}</span>
    </div>
    <div class="preview-stat-row">
      <span class="preview-stat-label">Rarity</span>
      <span class="preview-stat-value rarity-${String(rarity).toLowerCase().replace(/\s+/g, '-')}">${rarity}</span>
    </div>
    <div class="preview-stat-row">
      <span class="preview-stat-label">Level</span>
      <span class="preview-stat-value">${level}</span>
    </div>
    <div class="preview-big-stats">
      <div class="preview-big-stat preview-big-stat-atk">
        <span class="preview-big-stat-value">${atk}</span>
      </div>
      <div class="preview-big-stat preview-big-stat-def">
        <span class="preview-big-stat-value">${def}</span>
      </div>
      <div class="preview-big-stat preview-big-stat-spd">
        <span class="preview-big-stat-value">${spd}</span>
      </div>
    </div>
  `;

  const effectTitleEl = document.getElementById('effectTitle');
  const effectEl = document.getElementById('builderPreviewEffect');

  if (effectTitleEl) {
    effectTitleEl.textContent = resolved.effectTitle || '';
  }

  if (effectEl) {
    effectEl.textContent = resolved.effectText || 'No card text available.';
  }

  document.querySelectorAll('.builder-card').forEach(el => {
    el.classList.remove('selected');
    if (el.dataset.cardId === resolved.cardId) {
      el.classList.add('selected');
    }
  });
}

function updateBuilderPreviewFromSelectedDeck() {
  if (selectedDeck && selectedDeck.deck_data && selectedDeck.deck_data.cards) {
    const firstCardId = Object.keys(selectedDeck.deck_data.cards)[0];
    if (firstCardId) {
      setBuilderPreview(resolveCardData(builderOwnedCards[firstCardId] || { cardId: firstCardId }));
      return;
    }
  }

  builderPreviewName.textContent = 'Card Preview';
  builderPreviewImage.src = '';
  builderPreviewMeta.textContent = '';
}

function updateDeckHeader() {
  if (!selectedDeck) {
    currentDeckNameEl.textContent = 'No Deck Selected';
    currentDeckCountEl.textContent = '0 cards';
    currentDeckCountEl.style.color = 'white';
    return;
  }

  const count = getDeckCardCount(selectedDeck);
  const issues = getDeckValidationIssues(selectedDeck);

  currentDeckNameEl.textContent = selectedDeck.name || 'Unnamed Deck';

  if (issues.length) {
    currentDeckCountEl.textContent = `${count} / 30–50  •  ${issues.join(', ')}`;
    currentDeckCountEl.style.color = '#ff6b6b';
    currentDeckCountEl.style.textShadow = '0 0 8px rgba(255,107,107,0.25)';
  } else {
    currentDeckCountEl.textContent = `${count} / 30–50  •  Legal`;
    currentDeckCountEl.style.color = '#7CFF7C';
    currentDeckCountEl.style.textShadow = '0 0 10px rgba(124,255,124,0.45)';
  }
}

function addCardToSelectedDeck(cardId) {
  if (!selectedDeck) return;
  if (!builderOwnedCards[cardId]) return;

  normalizeDeck(selectedDeck);

  const owned = builderOwnedCards[cardId].amount || 0;
  const current = getSelectedDeckCardCount(cardId);
  const maxCopies = getMaxCopiesPerCard();

  if (current >= owned) return;
  if (current >= maxCopies) return;

  selectedDeck.deck_data.cards[cardId] = current + 1;

  syncSelectedDeckIntoCache();
  renderDeckBuilder();
}

function removeCardFromSelectedDeck(cardId) {
  if (!selectedDeck) return;

  normalizeDeck(selectedDeck);

  const current = selectedDeck.deck_data.cards[cardId] || 0;
  if (current <= 0) return;

  if (current === 1) {
    delete selectedDeck.deck_data.cards[cardId];
  } else {
    selectedDeck.deck_data.cards[cardId] = current - 1;
  }

  syncSelectedDeckIntoCache();
  renderDeckBuilder();
}

function getCardLevelNumber(card) {
  const value = card?.level ?? '';
  if (typeof value === 'number') return value;
  const match = String(value).match(/\d+/);
  return match ? Number(match[0]) : 0;
}

function isNormalSummonableFighter(card) {
  if (!card) return false;
  const type = String(card.type || '').trim().toUpperCase();
  return type === 'FIGHTER' && getCardLevelNumber(card) === 1;
}

function normalizePromotionName(card) {
  return String(card?.name || '').trim().replace(/\s+/g, ' ').toLowerCase();
}

function canPromoteFromTo(tributeCard, promotionCard) {
  if (!tributeCard || !promotionCard) return false;

  const tributeType = String(tributeCard.type || '').trim().toUpperCase();
  const promotionType = String(promotionCard.type || '').trim().toUpperCase();
  if (tributeType !== 'FIGHTER' || promotionType !== 'FIGHTER') return false;

  return getCardLevelNumber(tributeCard) > 0
    && getCardLevelNumber(promotionCard) === getCardLevelNumber(tributeCard) + 1
    && normalizePromotionName(tributeCard) === normalizePromotionName(promotionCard);
}

function getSelfHandCardByUid(uid) {
  const hand = currentDuelState?.selfPlayer?.hand || [];
  return hand.find(card => card.uid === uid) || null;
}

function getPromotionTributeZoneIndex(promotionCard) {
  const zones = currentDuelState?.selfPlayer?.fighterZones || [];
  for (let i = 0; i < zones.length; i++) {
    if (canPromoteFromTo(zones[i], promotionCard)) {
      return i + 1;
    }
  }
  return null;
}

function isPromotionSummonableFighter(card) {
  return !!getPromotionTributeZoneIndex(card);
}

function hasOpenFighterZone(zones) {
  for (let i = 0; i < 3; i++) {
    if (!(zones || [])[i]) {
      return true;
    }
  }

  return false;
}

function canPlayHandCard(card, canNormalSummon, selfZones) {
  if (!canNormalSummon || !card) return false;
  if (isPromotionSummonableFighter(card)) return true;
  return isNormalSummonableFighter(card) && hasOpenFighterZone(selfZones);
}

function updateHpDisplay(el, value) {
  if (!el) return;

  const hp = Number(value) || 0;
  el.textContent = hp;
  el.classList.toggle('low-hp', hp > 0 && hp < 200);
}

function renderTableZone(card, side, zoneIndex) {
  const zone = document.createElement('div');
  zone.className = 'table-zone';
  zone.dataset.side = side;
  zone.dataset.zoneIndex = String(zoneIndex);

  if (!card) {
    zone.classList.add('empty');
    return zone;
  }

  if (card.hasAttacked) zone.classList.add('used');

  const img = document.createElement('img');
  img.src = getCardImagePathFromPayload(card);
  zone.appendChild(img);

  const statStrip = document.createElement('div');
  statStrip.className = 'table-card-stats';
  statStrip.innerHTML = `
    <div class="table-card-stat atk"><strong>${card.attack ?? '-'}</strong></div>
    <div class="table-card-stat def"><strong>${card.defense ?? '-'}</strong></div>
    <div class="table-card-stat spd"><strong>${card.speed ?? '-'}</strong></div>
  `;
  zone.appendChild(statStrip);

  const stateLabel = document.createElement('div');
  stateLabel.className = 'table-state-label';
  zone.appendChild(stateLabel);

  zone.addEventListener('click', () => {
    setDuelPreviewCard(card);
  });

  return zone;
}

function closeTableGraveyard() {
  if (!openTableGraveSide) return;
  openTableGraveSide = null;
  renderTableGraveyard();
}

function setDuelPreviewCard(card) {
  tablePreviewCard = card || null;
  renderTablePreview();
}

function renderTablePreview() {
  if (!tablePreviewPanel) return;

  if (!tablePreviewCard) {
    tablePreviewPanel.classList.add('empty');
    if (tablePreviewImage) tablePreviewImage.src = '';
    if (tablePreviewName) tablePreviewName.textContent = 'Select a card';
    if (tablePreviewMeta) tablePreviewMeta.textContent = 'Field cards and hand cards appear here.';
    if (tablePreviewStats) tablePreviewStats.innerHTML = '';
    if (tablePreviewEffect) tablePreviewEffect.innerHTML = '';
    return;
  }

  const card = tablePreviewCard;
  tablePreviewPanel.classList.remove('empty');
  if (tablePreviewImage) tablePreviewImage.src = getCardImagePathFromPayload(card);
  if (tablePreviewName) tablePreviewName.textContent = card.name || card.cardId || 'Unknown Card';
  if (tablePreviewMeta) {
    const meta = [
      card.rarity,
      card.type,
      card.job,
      card.level ? `Lv. ${card.level}` : null,
      card.setCode,
      card.edition
    ].filter(Boolean);

    tablePreviewMeta.textContent = meta.join(' / ') || 'BStar Card';
  }

  if (tablePreviewStats) {
    tablePreviewStats.innerHTML = `
      <div class="table-preview-stat atk"><strong>${card.attack ?? '-'}</strong></div>
      <div class="table-preview-stat def"><strong>${card.defense ?? '-'}</strong></div>
      <div class="table-preview-stat spd"><strong>${card.speed ?? '-'}</strong></div>
    `;
  }

  if (tablePreviewEffect) {
    const title = card.effectTitle || 'Effect';
    const text = card.effectText || 'No effect text.';
    tablePreviewEffect.innerHTML = `
      <div class="table-preview-effect-title">${title}</div>
      <div class="table-preview-effect-text">${text}</div>
    `;
  }
}

function renderTableGraveyard() {
  if (!currentDuelState || !tableSelfGraveBtn || !tableOpponentGraveBtn || !tableGraveList) return;

  const selfGrave = currentDuelState.selfPlayer?.graveyard || [];
  const oppGrave = currentDuelState.opponentPlayer?.graveyard || [];
  const selfLastGrave = selfGrave[selfGrave.length - 1] || null;
  const oppLastGrave = oppGrave[oppGrave.length - 1] || null;

  tableSelfGraveBtn.textContent = `YOUR CEMETERY ${selfGrave.length}`;
  tableOpponentGraveBtn.textContent = `OPPONENT CEMETERY ${oppGrave.length}`;
  tableSelfGraveBtn.classList.toggle('hidden', openTableGraveSide !== 'self');
  tableOpponentGraveBtn.classList.toggle('hidden', openTableGraveSide !== 'opponent');
  tableSelfGraveBtn.classList.toggle('active', openTableGraveSide === 'self');
  tableOpponentGraveBtn.classList.toggle('active', openTableGraveSide === 'opponent');
  tableSelfCemeterySlot?.classList.toggle('active', openTableGraveSide === 'self');
  tableOpponentCemeterySlot?.classList.toggle('active', openTableGraveSide === 'opponent');

  if (tableSelfCemeteryImage) {
    tableSelfCemeteryImage.src = selfLastGrave ? getCardImagePathFromPayload(selfLastGrave) : '';
    tableSelfCemeteryImage.classList.toggle('hidden', !selfLastGrave);
  }

  if (tableOpponentCemeteryImage) {
    tableOpponentCemeteryImage.src = oppLastGrave ? getCardImagePathFromPayload(oppLastGrave) : '';
    tableOpponentCemeteryImage.classList.toggle('hidden', !oppLastGrave);
  }

  if (!openTableGraveSide) {
    tableGravePanel?.classList.add('hidden');
    tableGravePanel?.classList.remove('self', 'opponent');
    tableGraveList.classList.add('hidden');
    tableGraveList.innerHTML = '';
    return;
  }

  const cards = openTableGraveSide === 'self' ? selfGrave : oppGrave;
  tableGravePanel?.classList.remove('hidden');
  tableGravePanel?.classList.toggle('self', openTableGraveSide === 'self');
  tableGravePanel?.classList.toggle('opponent', openTableGraveSide === 'opponent');
  tableGraveList.classList.remove('hidden');
  tableGraveList.innerHTML = '';

  if (!cards.length) {
    const empty = document.createElement('div');
    empty.className = 'table-grave-empty';
    empty.textContent = 'No cards';
    tableGraveList.appendChild(empty);
    return;
  }

  for (const card of cards) {
    const row = document.createElement('button');
    row.className = 'table-grave-card';
    row.type = 'button';

    const img = document.createElement('img');
    img.src = getCardImagePathFromPayload(card);
    row.appendChild(img);

    const label = document.createElement('span');
    label.textContent = card.name || card.cardId || 'Unknown Card';
    row.appendChild(label);

    row.addEventListener('click', () => setDuelPreviewCard(card));
    tableGraveList.appendChild(row);
  }
}

function renderTableOpponentHandBacks() {
  if (!tableOpponentHandBacks || !currentDuelState) return;

  const count = Math.min(currentDuelState.opponentPlayer?.handCount || 0, 9);
  tableOpponentHandBacks.innerHTML = '';

  for (let i = 0; i < count; i++) {
    const back = document.createElement('div');
    back.className = 'table-opponent-hand-card';
    tableOpponentHandBacks.appendChild(back);
  }
}

function getTableZoneSnapshotFromState(duelState) {
  const snapshot = {};
  const selfZones = duelState?.selfPlayer?.fighterZones || [];
  const oppZones = duelState?.opponentPlayer?.fighterZones || [];

  for (let i = 0; i < 3; i++) {
    snapshot[`self-${i + 1}`] = selfZones[i]?.uid || null;
    snapshot[`opponent-${i + 1}`] = oppZones[i]?.uid || null;
  }

  return snapshot;
}

function addTableZoneTransitionClass(zone, side, zoneIndex, card) {
  if (!tableZoneSnapshot) return;

  const key = `${side}-${zoneIndex}`;
  const previousUid = tableZoneSnapshot[key] || null;
  const currentUid = card?.uid || null;

  if (!currentUid && previousUid) {
    zone.classList.add('zone-vacated');
  }
}

function getTableHandCardElement(cardUid) {
  const cards = tableHandRow?.querySelectorAll('.table-hand-card') || [];
  for (const el of cards) {
    if (el.dataset.cardUid === cardUid) {
      return el;
    }
  }
  return null;
}

function getTableCemeteryElementForSide(side) {
  return side === 'opponent' ? tableOpponentCemeterySlot : tableSelfCemeterySlot;
}

function getTableGraveSnapshotFromState(duelState) {
  return {
    self: duelState?.selfPlayer?.graveyardCount || 0,
    opponent: duelState?.opponentPlayer?.graveyardCount || 0
  };
}

function markTableCemeteryReceiving(side, duration = 720) {
  const cemeteryEl = getTableCemeteryElementForSide(side);
  if (!cemeteryEl) return;

  cemeteryEl.classList.add('receiving-card');
  setTimeout(() => {
    cemeteryEl.classList.remove('receiving-card');
  }, duration);
}

function animateTableCardTravel(fromEl, toEl, card, options = {}) {
  if (!fromEl || !toEl) return;

  const fromRect = fromEl.getBoundingClientRect();
  const toRect = toEl.getBoundingClientRect();
  const width = options.width || Math.min(Math.max(fromRect.width, 82), 150);
  const duration = options.duration || 620;
  const ghost = document.createElement('div');
  ghost.className = `table-card-travel-ghost ${options.variant || ''}`.trim();
  ghost.style.left = `${fromRect.left + fromRect.width / 2}px`;
  ghost.style.top = `${fromRect.top + fromRect.height / 2}px`;
  ghost.style.width = `${width}px`;
  ghost.style.animationDuration = `${duration}ms`;
  ghost.style.setProperty('--travel-dx', `${(toRect.left + toRect.width / 2) - (fromRect.left + fromRect.width / 2)}px`);
  ghost.style.setProperty('--travel-dy', `${(toRect.top + toRect.height / 2) - (fromRect.top + fromRect.height / 2)}px`);

  if (options.variant === 'cemetery') {
    toEl.classList.add('receiving-card');
    setTimeout(() => toEl.classList.remove('receiving-card'), duration);
  }

  const img = document.createElement('img');
  img.src = card ? getThumbImagePath(card) : '';
  img.onerror = () => {
    img.onerror = null;
    img.src = card ? getCardImagePathFromPayload(card) : '';
  };
  img.alt = '';
  ghost.appendChild(img);

  document.body.appendChild(ghost);
  setTimeout(() => ghost.remove(), duration);
}

function canCurrentViewerDraw() {
  return currentDuelState
    && currentDuelState.status === 'active'
    && currentDuelState.turnPlayer === currentDuelState.viewerIndex
    && currentDuelState.phase === 'draw'
    && currentDuelState.hasDrawnThisTurn !== true;
}

function animateTableDraw() {
  if (!tableSelfDeckSlot || !tableHandRow) return;

  const deckRect = tableSelfDeckSlot.getBoundingClientRect();
  const handRect = tableHandRow.getBoundingClientRect();
  const ghost = document.createElement('div');
  ghost.className = 'table-draw-card-ghost';
  ghost.style.left = `${deckRect.left + deckRect.width / 2}px`;
  ghost.style.top = `${deckRect.top + deckRect.height / 2}px`;
  ghost.style.setProperty('--draw-dx', `${(handRect.left + handRect.width / 2) - (deckRect.left + deckRect.width / 2)}px`);
  ghost.style.setProperty('--draw-dy', `${(handRect.top + 30) - (deckRect.top + deckRect.height / 2)}px`);

  document.body.appendChild(ghost);
  setTimeout(() => ghost.remove(), 520);
}

function drawCardForTurn() {
  if (!canCurrentViewerDraw() || tableDrawAnimating) return;

  tableDrawAnimating = true;
  animateTableDraw();

  setTimeout(() => {
    fetch(`https://${GetParentResourceName()}/duelDrawCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });

    setTimeout(() => {
      tableDrawAnimating = false;
    }, 260);
  }, 240);
}

function clearDuelSelections() {
  const hadSelection = selectedHandCardUid || selectedAttackerZoneIndex;
  selectedHandCardUid = null;
  selectedAttackerZoneIndex = null;
  return !!hadSelection;
}

function reconcileDuelSelections() {
  if (!currentDuelState || currentDuelState.status !== 'active') {
    clearDuelSelections();
    return;
  }

  const isMyTurn = currentDuelState.turnPlayer === currentDuelState.viewerIndex;
  const isMainPhase = currentDuelState.phase === 'main';
  const isBattlePhase = currentDuelState.phase === 'battle';
  const canAttackThisTurn = isMyTurn && isBattlePhase && !(currentDuelState.turnNumber === 1 && currentDuelState.firstTurnPlayer === currentDuelState.viewerIndex);

  if (!isMyTurn || !isMainPhase || currentDuelState.selfPlayer?.hasSummonedThisTurn) {
    selectedHandCardUid = null;
  }

  if (!canAttackThisTurn) {
    selectedAttackerZoneIndex = null;
    return;
  }

  const attacker = currentDuelState.selfPlayer?.fighterZones?.[selectedAttackerZoneIndex - 1];
  if (!attacker || attacker.hasAttacked) {
    selectedAttackerZoneIndex = null;
  }
}

function getDuelResultText() {
  if (!currentDuelState || currentDuelState.status !== 'finished') {
    return null;
  }

  let title = 'DEFEAT';
  if (currentDuelState.winner === currentDuelState.viewerIndex) {
    title = 'VICTORY';
  } else if (currentDuelState.winner === 0) {
    title = 'DRAW';
  }

  const reasonMap = {
    life_points: 'HP depleted',
    deck_out: 'Deck out',
    draw: 'Draw',
    surrender: 'Surrender'
  };

  const selfLp = currentDuelState.selfPlayer?.lifePoints ?? 0;
  const opponentLp = currentDuelState.opponentPlayer?.lifePoints ?? 0;

  return {
    title,
    reason: reasonMap[currentDuelState.winReason] || 'Duel finished',
    meta: `Your HP ${selfLp} / Opponent HP ${opponentLp}`
  };
}

function renderDuelResultOverlay() {
  const result = getDuelResultText();
  const overlay = duelTableMode ? tableResultOverlay : duelResultOverlay;
  const titleEl = duelTableMode ? tableResultTitle : duelResultTitle;
  const reasonEl = duelTableMode ? tableResultReason : duelResultReason;
  const metaEl = duelTableMode ? tableResultMeta : duelResultMeta;
  const otherOverlay = duelTableMode ? duelResultOverlay : tableResultOverlay;

  otherOverlay?.classList.add('hidden');

  if (!overlay || !result) {
    tableResultOverlay?.classList.add('hidden');
    duelResultOverlay?.classList.add('hidden');
    return;
  }

  overlay.classList.remove('hidden');
  overlay.classList.toggle('victory', result.title === 'VICTORY');
  overlay.classList.toggle('defeat', result.title === 'DEFEAT');
  overlay.classList.toggle('draw', result.title === 'DRAW');

  if (titleEl) titleEl.textContent = result.title;
  if (reasonEl) reasonEl.textContent = result.reason;
  if (metaEl) metaEl.textContent = result.meta;
}

function renderTableDuelUi() {
  if (!currentDuelState) return;

  const nextZoneSnapshot = getTableZoneSnapshotFromState(currentDuelState);
  const nextGraveSnapshot = getTableGraveSnapshotFromState(currentDuelState);

  const isMyTurn = currentDuelState.turnPlayer === currentDuelState.viewerIndex;
  const isMainPhase = currentDuelState.phase === 'main';
  const isBattlePhase = currentDuelState.phase === 'battle';
  const isDiscardPhase = currentDuelState.phase === 'discard';
  const canAttackThisTurn = isMyTurn
    && isBattlePhase
    && !(currentDuelState.turnNumber === 1 && currentDuelState.firstTurnPlayer === currentDuelState.viewerIndex);
  const handSize = currentDuelState.selfPlayer?.hand?.length || 0;
  const discardCount = Math.max(0, handSize - 9);
  const canNormalSummon = isMyTurn && isMainPhase && !currentDuelState.selfPlayer?.hasSummonedThisTurn;
  const canDraw = canCurrentViewerDraw();

  tablePhaseBadge.textContent = `${String(currentDuelState.phase || 'draw').toUpperCase()} PHASE`;
  if (tableDrawPrompt) {
    tableDrawPrompt.textContent = isDiscardPhase && discardCount > 0 ? `Discard ${discardCount} card${discardCount === 1 ? '' : 's'}` : 'Draw a card!';
    tableDrawPrompt.classList.toggle('hidden', !canDraw && !(isDiscardPhase && discardCount > 0));
  }
  tableSelfDeckSlot?.classList.toggle('draw-ready', canDraw);
  tableNextPhaseBtn.disabled = !isMyTurn
    || currentDuelState.status !== 'active'
    || currentDuelState.phase === 'draw'
    || currentDuelState.phase === 'discard';
  tableEndTurnBtn.disabled = !isMyTurn || currentDuelState.status !== 'active' || (isDiscardPhase && discardCount > 0);

  updateHpDisplay(tableSelfLP, currentDuelState.selfPlayer?.lifePoints ?? 0);
  updateHpDisplay(tableOpponentLP, currentDuelState.opponentPlayer?.lifePoints ?? 0);
  if (tableOpponentDeckCount) tableOpponentDeckCount.textContent = `OPPONENT DECK ${currentDuelState.opponentPlayer?.deckCount ?? 0}`;
  if (tableSelfDeckCount) tableSelfDeckCount.textContent = `YOUR DECK ${currentDuelState.selfPlayer?.deckCount ?? 0}`;
  if (tableOpponentCemeteryCount) tableOpponentCemeteryCount.textContent = `OPPONENT CEMETERY ${currentDuelState.opponentPlayer?.graveyardCount ?? 0}`;
  if (tableSelfCemeteryCount) tableSelfCemeteryCount.textContent = `YOUR CEMETERY ${currentDuelState.selfPlayer?.graveyardCount ?? 0}`;

  tableOpponentZones.innerHTML = '';
  tableSelfZones.innerHTML = '';
  tableHandRow.innerHTML = '';
  renderTablePreview();
  renderTableGraveyard();
  if (tableGraveSnapshot) {
    if (nextGraveSnapshot.self > tableGraveSnapshot.self) {
      markTableCemeteryReceiving('self');
    }
    if (nextGraveSnapshot.opponent > tableGraveSnapshot.opponent) {
      markTableCemeteryReceiving('opponent');
    }
  }
  renderTableOpponentHandBacks();
  renderDuelResultOverlay();

  const oppZones = currentDuelState.opponentPlayer?.fighterZones || [null, null, null];
  const selfZones = currentDuelState.selfPlayer?.fighterZones || [null, null, null];
  const selectedHandCard = getSelfHandCardByUid(selectedHandCardUid);

  for (let i = 0; i < 3; i++) {
    const card = oppZones[i] || null;
    const zone = renderTableZone(card, 'opponent', i + 1);
    addTableZoneTransitionClass(zone, 'opponent', i + 1, card);

    if (selectedAttackerZoneIndex && canAttackThisTurn && card) {
      zone.classList.add('targetable');
      zone.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/duelAttack`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            attackerZoneIndex: selectedAttackerZoneIndex,
            targetType: 'fighter',
            targetZoneIndex: i + 1
          })
        });

        selectedAttackerZoneIndex = null;
      });
    }

    tableOpponentZones.appendChild(zone);
  }

  for (let i = 0; i < 3; i++) {
    const card = selfZones[i] || null;
    const zone = renderTableZone(card, 'self', i + 1);
    addTableZoneTransitionClass(zone, 'self', i + 1, card);

    if (!card && selectedHandCardUid && canNormalSummon && isNormalSummonableFighter(selectedHandCard)) {
      zone.classList.add('targetable');
      zone.addEventListener('click', () => {
        animateTableCardTravel(getTableHandCardElement(selectedHandCardUid), zone, selectedHandCard, {
          variant: 'summon',
          width: 110
        });

        fetch(`https://${GetParentResourceName()}/duelSummonFighter`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            handUid: selectedHandCardUid,
            zoneIndex: i + 1
          })
        });

        selectedHandCardUid = null;
      });
    }

    if (card && selectedHandCardUid && canNormalSummon && canPromoteFromTo(card, selectedHandCard)) {
      zone.classList.add('promote-target');
      zone.addEventListener('click', () => {
        animateTableCardTravel(zone, tableSelfCemeterySlot, card, {
          variant: 'cemetery',
          width: 116
        });
        animateTableCardTravel(getTableHandCardElement(selectedHandCardUid), zone, selectedHandCard, {
          variant: 'summon',
          width: 110
        });

        fetch(`https://${GetParentResourceName()}/duelPromoteFighter`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            handUid: selectedHandCardUid,
            tributeZoneIndex: i + 1
          })
        });

        selectedHandCardUid = null;
      });
    }

    if (card && canAttackThisTurn && !card.hasAttacked) {
      zone.classList.add('attack-ready');
      zone.addEventListener('click', () => {
        selectedHandCardUid = null;
        selectedAttackerZoneIndex = selectedAttackerZoneIndex === (i + 1) ? null : i + 1;
        renderDuelUi();
      });
    }

    if (canAttackThisTurn && selectedAttackerZoneIndex === i + 1) {
      zone.classList.add('selected');
    }

    tableSelfZones.appendChild(zone);
  }

  const opponentHasFighters = oppZones.some(Boolean);

  if (selectedAttackerZoneIndex && canAttackThisTurn && !opponentHasFighters) {
    const direct = document.createElement('div');
    direct.className = 'table-zone targetable table-direct-target';
    direct.textContent = 'DIRECT';
    direct.dataset.side = 'opponent';
    direct.dataset.zoneIndex = 'direct';

    direct.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/duelAttack`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          attackerZoneIndex: selectedAttackerZoneIndex,
          targetType: 'direct',
          targetZoneIndex: 0
        })
      });

      selectedAttackerZoneIndex = null;
    });

    tableOpponentZones.appendChild(direct);
  }

  const hand = currentDuelState.selfPlayer?.hand || [];

  for (const card of hand) {
    const div = document.createElement('div');
    div.className = 'table-hand-card';
    div.dataset.cardUid = card.uid;
    const canSummonCard = canPlayHandCard(card, canNormalSummon, selfZones);

    if (canSummonCard) {
      div.classList.add('summonable');
    }

    if (canNormalSummon && isPromotionSummonableFighter(card)) {
      div.classList.add('promotion-ready');
    }

    if (isMyTurn && isDiscardPhase && handSize > 9) {
      div.classList.add('discardable');
    }

    if (selectedHandCardUid === card.uid) {
      div.classList.add('selected');
    }

    const img = document.createElement('img');
    setCardThumbImage(img, card);
    div.appendChild(img);

    div.addEventListener('click', () => {
      setDuelPreviewCard(card);

      if (isMyTurn && isDiscardPhase && handSize > 9) {
        fetch(`https://${GetParentResourceName()}/duelDiscardCard`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ handUid: card.uid })
        });
        return;
      }

      if (!canSummonCard) return;

      selectedAttackerZoneIndex = null;
      selectedHandCardUid = selectedHandCardUid === card.uid ? null : card.uid;
      renderDuelUi();
    });

    tableHandRow.appendChild(div);
  }

  tableZoneSnapshot = nextZoneSnapshot;
  tableGraveSnapshot = nextGraveSnapshot;
}

function hideCard() {
  viewerWrap.classList.add('hidden');
  cardImage.src = '';
  cardImage.classList.remove('zoomed');
  isZoomed = false;
  resetTilt();
}

function refreshDeckBuilder(selectDeckId = null) {
  if (!currentDeckBoxId) return;

  fetch(`https://${GetParentResourceName()}/refreshDeckBuilder`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      window.BSTAR_CARD_DEFS = data.cardCatalog || window.BSTAR_CARD_DEFS || {};
      builderOwnedCards = data.storedCards || {};
      currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));

      if (selectDeckId) {
        const found = currentDecks.find(d => d.id === selectDeckId);
        selectedDeck = found ? normalizeDeck(clone(found)) : null;
      } else if (selectedDeck) {
        const found = currentDecks.find(d => d.id === selectedDeck.id);
        selectedDeck = found ? normalizeDeck(clone(found)) : null;
      } else if (currentDecks.length) {
        selectedDeck = normalizeDeck(clone(currentDecks[0]));
      } else {
        selectedDeck = null;
      }

      renderDeckBuilder();
      hookFilterInputs();
    });
}

function renameSelectedDeck() {
  if (!selectedDeck) return;

  openModal({
    title: 'Rename Deck',
    text: 'Enter a new name for this deck.',
    showInput: true,
    inputValue: selectedDeck.name || '',
    confirmText: 'Rename',
    onConfirm: (value) => {
      const newName = value.trim();
      if (!newName) return;

      selectedDeck.name = newName;
      syncSelectedDeckIntoCache();
      updateDeckHeader();

      fetch(`https://${GetParentResourceName()}/saveDeck`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          deckBoxId: currentDeckBoxId,
          deckId: selectedDeck.id,
          deckName: selectedDeck.name,
          deckData: selectedDeck.deck_data
        })
      }).then(() => {
        setTimeout(() => refreshDeckBuilder(selectedDeck.id), 150);
      });
    }
  });
}

function getCardImagePathFromPayload(card) {
  if (!card) return '';
  const file = card.inventoryImage || 'default.png';
  return `nui://bstar_cards/html/images/cards/${file}`;
}

function openDuelUi(duel, tableMode = false) {
  currentDuelState = duel;
  selectedHandCardUid = null;
  selectedAttackerZoneIndex = null;
  duelTableMode = tableMode;
  tablePreviewCard = null;
  openTableGraveSide = null;
  tableZoneSnapshot = null;
  tableGraveSnapshot = null;

  console.log('[BStar NUI] openDuelUi tableMode:', tableMode);

  hideAll();
  app.classList.remove('hidden');

  if (duelTableMode) {
    tableDuelWrap.classList.remove('hidden');
    duelWrap.classList.add('hidden');
  } else {
    duelWrap.classList.remove('hidden');
    tableDuelWrap.classList.add('hidden');
  }

  renderDuelUi();
}

function updateDuelUi(duel, tableMode = duelTableMode) {
  currentDuelState = duel;
  duelTableMode = tableMode;
  reconcileDuelSelections();
  if (!canCurrentViewerDraw()) {
    tableDrawAnimating = false;
  }

  if ((duelTableMode && tableDuelWrap.classList.contains('hidden')) ||
      (!duelTableMode && duelWrap.classList.contains('hidden'))) {
    openDuelUi(duel, duelTableMode);
    return;
  }

  renderDuelUi();
}

function closeDuelUi(notifyLua = true) {
  currentDuelState = null;
  selectedHandCardUid = null;
  selectedAttackerZoneIndex = null;
  duelTableMode = false;
  tablePreviewCard = null;
  openTableGraveSide = null;
  tableDrawAnimating = false;
  tableZoneSnapshot = null;
  tableGraveSnapshot = null;
  tableResultOverlay?.classList.add('hidden');
  duelResultOverlay?.classList.add('hidden');

  duelWrap.classList.add('hidden');
  tableDuelWrap.classList.add('hidden');
  app.classList.add('hidden');

  if (notifyLua) {
    fetch(`https://${GetParentResourceName()}/duelCloseUi`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  }
}

function renderZoneCard(zoneCard, side, zoneIndex, extraClass = '') {
  const zone = document.createElement('div');
  zone.className = `duel-zone ${extraClass}`.trim();
  zone.dataset.side = side;
  zone.dataset.zoneIndex = String(zoneIndex);

  if (!zoneCard) {
    zone.classList.add('empty');
    return zone;
  }

  zone.dataset.cardUid = zoneCard.uid || '';
  zone.dataset.cardId = zoneCard.cardId || '';

  const img = document.createElement('img');
  img.src = getCardImagePathFromPayload(zoneCard);

  zone.appendChild(img);
  return zone;
}

function renderOpponentZones() {
  duelOpponentFighterZones.innerHTML = '';

  const zones = currentDuelState?.opponentPlayer?.fighterZones || [null, null, null];
  const isMyTurn = currentDuelState?.turnPlayer === currentDuelState?.viewerIndex;
  const isBattlePhase = currentDuelState?.phase === 'battle';
  const canAttackThisTurn = isMyTurn && isBattlePhase && !(currentDuelState?.turnNumber === 1 && currentDuelState?.firstTurnPlayer === currentDuelState?.viewerIndex);

  for (let i = 0; i < 3; i++) {
    const zoneCard = zones[i] || null;
    const zoneEl = renderZoneCard(zoneCard, 'opponent', i + 1);

    if (selectedAttackerZoneIndex && canAttackThisTurn && zoneCard) {
      zoneEl.classList.add('summon-target');
      zoneEl.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/duelAttack`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            attackerZoneIndex: selectedAttackerZoneIndex,
            targetType: 'fighter',
            targetZoneIndex: i + 1
          })
        });

        selectedAttackerZoneIndex = null;
      });
    }

    duelOpponentFighterZones.appendChild(zoneEl);
  }

  const occupiedOpponent = zones.some(z => !!z);
  if (selectedAttackerZoneIndex && canAttackThisTurn && !occupiedOpponent) {
    const directZone = document.createElement('div');
    directZone.className = 'duel-zone summon-target duel-direct-target';
    directZone.dataset.side = 'opponent';
    directZone.dataset.zoneIndex = 'direct';
    directZone.textContent = 'Direct Attack';

    directZone.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/duelAttack`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          attackerZoneIndex: selectedAttackerZoneIndex,
          targetType: 'direct',
          targetZoneIndex: 0
        })
      });

      selectedAttackerZoneIndex = null;
    });

    duelOpponentFighterZones.appendChild(directZone);
  }
}

function renderSelfZones() {
  duelSelfFighterZones.innerHTML = '';

  const zones = currentDuelState?.selfPlayer?.fighterZones || [null, null, null];
  const isMyTurn = currentDuelState?.turnPlayer === currentDuelState?.viewerIndex;
  const isMainPhase = currentDuelState?.phase === 'main';
  const isBattlePhase = currentDuelState?.phase === 'battle';
  const canAttackThisTurn = isMyTurn && isBattlePhase && !(currentDuelState?.turnNumber === 1 && currentDuelState?.firstTurnPlayer === currentDuelState?.viewerIndex);
  const canNormalSummon = isMyTurn && isMainPhase && !currentDuelState.selfPlayer?.hasSummonedThisTurn;
  const selectedHandCard = getSelfHandCardByUid(selectedHandCardUid);

  for (let i = 0; i < 3; i++) {
    const zoneCard = zones[i] || null;
    const zoneEl = renderZoneCard(zoneCard, 'self', i + 1);

    if (!zoneCard && selectedHandCardUid && canNormalSummon && isNormalSummonableFighter(selectedHandCard)) {
      zoneEl.classList.add('summon-target');
      zoneEl.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/duelSummonFighter`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            handUid: selectedHandCardUid,
            zoneIndex: i + 1
          })
        });

        selectedHandCardUid = null;
      });
    }

    if (zoneCard && selectedHandCardUid && canNormalSummon && canPromoteFromTo(zoneCard, selectedHandCard)) {
      zoneEl.classList.add('promotion-target');
      zoneEl.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/duelPromoteFighter`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            handUid: selectedHandCardUid,
            tributeZoneIndex: i + 1
          })
        });

        selectedHandCardUid = null;
      });
    }

    if (zoneCard && canAttackThisTurn) {
      if (zoneCard.hasAttacked) {
        zoneEl.classList.add('duel-zone-used');
      } else {
        zoneEl.classList.add('attack-ready');
        zoneEl.addEventListener('click', () => {
          selectedHandCardUid = null;
          selectedAttackerZoneIndex = selectedAttackerZoneIndex === (i + 1) ? null : (i + 1);
          renderDuelUi();
        });
      }

      if (selectedAttackerZoneIndex === (i + 1)) {
        zoneEl.classList.add('duel-zone-selected');
      }
    }

    duelSelfFighterZones.appendChild(zoneEl);
  }
}

let displayedSelfLP = null;
let displayedOpponentLP = null;

function animateNumber(from, to, duration, onUpdate, onComplete) {
  const start = performance.now();

  function tick(now) {
    const progress = Math.min((now - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);

    const value = Math.round(from + ((to - from) * eased));

    onUpdate(value);

    if (progress < 1) {
      requestAnimationFrame(tick);
    } else if (onComplete) {
      onComplete();
    }
  }

  requestAnimationFrame(tick);
}

function triggerLPDamageEffect(el) {
  el.classList.remove('lp-damaged');
  void el.offsetWidth;
  el.classList.add('lp-damaged');
}

function updateLifePointsDisplay() {
  if (!currentDuelState) return;

  const selfLP = currentDuelState.selfPlayer.lifePoints || 0;
  const opponentLP = currentDuelState.opponentPlayer.lifePoints || 0;

  if (displayedSelfLP === null) {
    displayedSelfLP = selfLP;
    updateHpDisplay(duelSelfLP, selfLP);
  }

  if (displayedOpponentLP === null) {
    displayedOpponentLP = opponentLP;
    updateHpDisplay(duelOpponentLP, opponentLP);
  }

  if (displayedSelfLP !== selfLP) {
    const old = displayedSelfLP;

    animateNumber(old, selfLP, 450, (value) => {
      duelSelfLP.textContent = value;
    });
    duelSelfLP.classList.toggle('low-hp', selfLP > 0 && selfLP < 200);

    if (selfLP < old) {
      triggerLPDamageEffect(duelSelfLP);
    }

    displayedSelfLP = selfLP;
  }

  if (displayedOpponentLP !== opponentLP) {
    const old = displayedOpponentLP;

    animateNumber(old, opponentLP, 450, (value) => {
      duelOpponentLP.textContent = value;
    });
    duelOpponentLP.classList.toggle('low-hp', opponentLP > 0 && opponentLP < 200);

    if (opponentLP < old) {
      triggerLPDamageEffect(duelOpponentLP);
    }

    displayedOpponentLP = opponentLP;
  }
}

function renderHand() {
  duelHandCards.innerHTML = '';

  const hand = currentDuelState?.selfPlayer?.hand || [];
  const isMyTurn = currentDuelState?.turnPlayer === currentDuelState?.viewerIndex;
  const isMainPhase = currentDuelState?.phase === 'main';
  const isDiscardPhase = currentDuelState?.phase === 'discard';
  const canNormalSummon = isMyTurn && isMainPhase && !currentDuelState.selfPlayer?.hasSummonedThisTurn;
  const selfZones = currentDuelState?.selfPlayer?.fighterZones || [null, null, null];

  for (const card of hand) {
    const div = document.createElement('div');
    div.className = 'duel-hand-card';
    const canSummonCard = canPlayHandCard(card, canNormalSummon, selfZones);

    if (canSummonCard) {
      div.classList.add('summonable');
    }

    if (canNormalSummon && isPromotionSummonableFighter(card)) {
      div.classList.add('promotion-ready');
    }

    if (isMyTurn && isDiscardPhase && hand.length > 9) {
      div.classList.add('discardable');
    }

    if (selectedHandCardUid === card.uid) {
      div.classList.add('selected');
    }

    const img = document.createElement('img');
    setCardThumbImage(img, card);

    const name = document.createElement('div');
    name.className = 'duel-hand-card-name';
    name.textContent = card.name || card.cardId;

    div.appendChild(img);
    div.appendChild(name);

    div.addEventListener('click', () => {
      if (isMyTurn && isDiscardPhase && hand.length > 9) {
        fetch(`https://${GetParentResourceName()}/duelDiscardCard`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ handUid: card.uid })
        });
        return;
      }

      if (!canSummonCard) return;

      selectedAttackerZoneIndex = null;
      selectedHandCardUid = selectedHandCardUid === card.uid ? null : card.uid;
      renderDuelUi();
    });

    duelHandCards.appendChild(div);
  }
}

function renderDuelUi() {
  if (duelTableMode) {
    renderTableDuelUi();
    return;
  }
  if (!currentDuelState) return;

  duelTurnText.textContent = `Turn ${currentDuelState.turnNumber || 1}`;
  duelPhaseText.textContent = `${String(currentDuelState.phase || 'draw').toUpperCase()} PHASE`;
  if (duelAdvancePhaseBtn) {
    duelAdvancePhaseBtn.textContent = currentDuelState.phase === 'draw' ? 'Draw Card' : 'Next Phase';
  }

  const isMyTurn = currentDuelState.turnPlayer === currentDuelState.viewerIndex;
  duelStatusText.textContent = isMyTurn ? 'Your turn' : 'Opponent turn';

  duelOpponentDeckCount.textContent = `Deck: ${currentDuelState.opponentPlayer?.deckCount || 0}`;
  duelOpponentHandCount.textContent = `Hand: ${currentDuelState.opponentPlayer?.handCount || 0}`;
  duelOpponentGraveCount.textContent = `GY: ${currentDuelState.opponentPlayer?.graveyardCount || 0} • HP: ${currentDuelState.opponentPlayer?.lifePoints || 0}`;

  duelSelfDeckCount.textContent = `Deck: ${currentDuelState.selfPlayer?.deckCount || 0}`;
  duelSelfGraveCount.textContent = `GY: ${currentDuelState.selfPlayer?.graveyardCount || 0} • HP: ${currentDuelState.selfPlayer?.lifePoints || 0}`;

  if (currentDuelState.status === 'finished') {
    if (currentDuelState.winner === currentDuelState.viewerIndex) {
      duelStatusText.textContent = 'You win!';
    } else if (currentDuelState.winner === 0) {
      duelStatusText.textContent = 'Draw!';
    } else {
      duelStatusText.textContent = 'You lose!';
    }
  } else {
    const isMyTurn = currentDuelState.turnPlayer === currentDuelState.viewerIndex;
    duelStatusText.textContent = isMyTurn ? 'Your turn' : 'Opponent turn';
  }

  updateLifePointsDisplay();
  renderOpponentZones();
  renderSelfZones();
  renderHand();
  renderDuelResultOverlay();
}

function getZoneElement(side, zoneIndex) {
  const selector = `[data-side="${side}"][data-zone-index="${zoneIndex}"]`;

  if (duelTableMode) {
    return document.querySelector(`.table-zone${selector}`);
  }

  return document.querySelector(`.duel-zone${selector}`);
}

function getDirectAttackTargetElement(defenderSide) {
  if (duelTableMode) {
    return defenderSide === 'opponent'
      ? document.getElementById('tableOpponentLPWrap')
      : document.getElementById('tableSelfLPWrap');
  }

  return defenderSide === 'opponent' ? duelOpponentFighterZones : duelSelfFighterZones;
}

function spawnDamageNumberAt(x, y, amount) {
  const el = document.createElement('div');
  el.className = 'damage-popup';
  el.textContent = '-0';
  el.style.left = `${x}px`;
  el.style.top = `${y}px`;
  document.body.appendChild(el);

  const finalAmount = Number(amount) || 0;
  const startedAt = performance.now();
  const duration = 520;

  function tick(now) {
    const progress = Math.min(1, (now - startedAt) / duration);
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.max(1, Math.round(finalAmount * eased));
    el.textContent = `-${current}`;

    if (progress < 1) {
      requestAnimationFrame(tick);
    }
  }

  requestAnimationFrame(tick);

  setTimeout(() => {
    el.remove();
  }, 1200);
}

function spawnDamageNumberOnElement(targetEl, amount) {
  if (!targetEl || !amount || amount <= 0) return;

  const rect = targetEl.getBoundingClientRect();
  spawnDamageNumberAt(rect.left + rect.width / 2, rect.top + rect.height / 2, amount);
}

function spawnDodgeCalloutOnElement(targetEl, cardName) {
  if (!targetEl) return;

  const rect = targetEl.getBoundingClientRect();
  const el = document.createElement('div');
  el.className = 'dodge-callout';
  el.textContent = `${cardName || 'Card'} dodged the attack!`;
  el.style.left = `${rect.left + rect.width / 2}px`;
  el.style.top = `${Math.max(48, rect.top - 18)}px`;
  document.body.appendChild(el);

  setTimeout(() => {
    el.remove();
  }, 1800);
}

function animateAttackLine(fromEl, toEl) {
  if (!fromEl || !toEl) return;

  const fromRect = fromEl.getBoundingClientRect();
  const toRect = toEl.getBoundingClientRect();

  const x1 = fromRect.left + fromRect.width / 2;
  const y1 = fromRect.top + fromRect.height / 2;
  const x2 = toRect.left + toRect.width / 2;
  const y2 = toRect.top + toRect.height / 2;

  const dx = x2 - x1;
  const dy = y2 - y1;
  const length = Math.sqrt(dx * dx + dy * dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI);

  const line = document.createElement('div');
  line.className = 'attack-line';
  line.style.left = `${x1}px`;
  line.style.top = `${y1}px`;
  line.style.width = `${length}px`;
  line.style.transform = `translateY(-50%) rotate(${angle}deg)`;

  document.body.appendChild(line);

  setTimeout(() => {
    line.remove();
  }, 350);
}

function flashDestroyed(targetEl) {
  if (!targetEl) return;
  targetEl.classList.add('destroyed');
  setTimeout(() => {
    targetEl.classList.remove('destroyed');
  }, 600);
}

function pulseResolved(targetEl) {
  if (!targetEl) return;
  targetEl.classList.add('battle-resolve-hit');
  setTimeout(() => {
    targetEl.classList.remove('battle-resolve-hit');
  }, 350);
}

function animateDestroyedCardToCemetery(fromEl, side, card) {
  if (!duelTableMode || !fromEl || !card) return;

  const cemeteryEl = getTableCemeteryElementForSide(side);
  if (!cemeteryEl) return;

  setTimeout(() => {
    animateTableCardTravel(fromEl, cemeteryEl, card, {
      variant: 'cemetery',
      width: 116,
      duration: 680
    });
  }, 180);
}

function handleBattleEvent(result) {
  if (!result) return;

  const attackerSide = result.attackingPlayer === currentDuelState?.viewerIndex ? 'self' : 'opponent';
  const defenderSide = result.defendingPlayer === currentDuelState?.viewerIndex ? 'self' : 'opponent';

  const attackerEl = getZoneElement(attackerSide, result.attackerZoneIndex);
  let targetEl = null;

  if (result.targetType === 'fighter') {
    targetEl = getZoneElement(defenderSide, result.targetZoneIndex);
  } else if (result.targetType === 'direct') {
    targetEl = getDirectAttackTargetElement(defenderSide);
  }

  if (attackerEl && targetEl) {
    animateAttackLine(attackerEl, targetEl);
  }

  if (result.dodged) {
    spawnDodgeCalloutOnElement(targetEl, result.defenderCard?.name);
    return;
  }

  if (attackerEl) {
    pulseResolved(attackerEl);
  }

  if (targetEl) {
    pulseResolved(targetEl);
  }

  if (result.damageToDefenderPlayer && result.damageToDefenderPlayer > 0) {
    if (result.targetType === 'direct') {
      const rect = targetEl.getBoundingClientRect();
      spawnDamageNumberAt(rect.left + rect.width / 2, rect.top + 30, result.damageToDefenderPlayer);
    } else {
      spawnDamageNumberOnElement(targetEl, result.damageToDefenderPlayer);
    }
  }

  if (result.damageToAttackerPlayer && result.damageToAttackerPlayer > 0) {
    spawnDamageNumberOnElement(attackerEl, result.damageToAttackerPlayer);
  }

  if (result.attackerDestroyed) {
    animateDestroyedCardToCemetery(attackerEl, attackerSide, result.attackerCard);
    setTimeout(() => {
      flashDestroyed(attackerEl);
    }, 180);
  }

  if (result.defenderDestroyed) {
    animateDestroyedCardToCemetery(targetEl, defenderSide, result.defenderCard);
    setTimeout(() => {
      flashDestroyed(targetEl);
    }, 180);
  }
}

// ---------- Message handling ----------

window.addEventListener('message', (event) => {
  const data = event.data;

  if (data.action === 'showCard') {
    const card = data.card;
    if (!card || !card.image) return;

    hideAll();
    viewerWrap.classList.remove('hidden');
    cardImage.src = card.image;
    currentRotateX = 0;
    currentRotateY = 0;
    resetTilt();
    app.classList.remove('hidden');
    ensureAnimationLoop();
  }

  if (data.action === 'openDuelUi') {
    coinFlipWrap.classList.add('hidden');
    pendingCoinDuelId = null;
    openDuelUi(data.duel, !!data.tableMode);
  }

  if (data.action === 'updateDuelUi') {
    updateDuelUi(data.duel, !!data.tableMode);
  }

  if (data.action === 'closeDuelUi') {
    closeDuelUi(false);
  }

  if (data.action === 'hideCard') {
    hideCard();
  }

  if (data.action === 'openDeckBox') {
    openDeckBox(data);
  }

  if (data.action === 'openDeckBuilder') {
    openDeckHub(data);
  }

  if (data.action === 'openTableDeckSelect') {
    openDeckHub({
      ...data,
      mode: 'tableSelect'
    });
  }

  if (data.action === 'openCoinFlip') {
    openCoinFlip(data);
  }

  if (data.action === 'coinFlipResult') {
    showCoinFlipResult(data.result);
  }

  if (data.action === 'requestDuelSurrender') {
    requestDuelSurrender();
  }

  if (data.action === 'forceCloseAll') {
    hideAll();
    viewerOpenedFromDeckBox = false;
    viewerOpenedFromDeckBuilder = false;
  }

  if (data.action === 'battleEvent') {
    handleBattleEvent(data.data);
  }
});

// ---------- Event bindings ----------

document.addEventListener('contextmenu', (e) => {
  e.preventDefault();
});

uiModalCancelBtn.addEventListener('click', closeModal);

uiModalConfirmBtn.addEventListener('click', () => {
  if (activeModalAction) {
    activeModalAction(uiModalInput.value.trim());
  }
  closeModal();
});

coinHeadsBtn?.addEventListener('click', () => sendCoinChoice('heads'));
coinTailsBtn?.addEventListener('click', () => sendCoinChoice('tails'));
goFirstBtn?.addEventListener('click', () => chooseTurnOrder('first'));
goSecondBtn?.addEventListener('click', () => chooseTurnOrder('second'));

closeBtn.addEventListener('click', () => {
  closeFullViewer();
});

deckboxCloseBtn.addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/refreshDeckBuilder`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));

      if (selectedHubDeckId) {
        const found = currentDecks.find(d => d.id === selectedHubDeckId);
        selectedHubDeckId = found ? found.id : (currentDecks[0]?.id || null);
      } else {
        selectedHubDeckId = currentDecks[0]?.id || null;
      }

      hideAll();
      app.classList.remove('hidden');
      deckHubWrap.classList.remove('hidden');
      renderDeckHub();
    });
});

deckHubCloseBtn.addEventListener('click', () => {
  hideAll();

  const closeAction = deckHubMode === 'tableSelect' ? 'closeTableDeckSelect' : 'closeDeckBuilder';
  deckHubMode = 'manage';
  pendingTableDuelId = null;

  fetch(`https://${GetParentResourceName()}/${closeAction}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
});

deckHubNewBtn.addEventListener('click', () => {
  openModal({
    title: 'Create New Deck',
    text: 'Enter a name for the new deck.',
    showInput: true,
    inputValue: '',
    confirmText: 'Create',
    onConfirm: (value) => {
      const deckName = value || `New Deck ${Date.now()}`;

      fetch(`https://${GetParentResourceName()}/createDeck`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          deckBoxId: currentDeckBoxId,
          deckName
        })
      }).then(() => {
        setTimeout(refreshDeckHub, 150);
      });
    }
  });
});

deckHubEditBtn.addEventListener('click', () => {
  if (deckHubMode === 'tableSelect') {
    startSelectedTableDuelDeck();
    return;
  }

  const deck = getSelectedHubDeck();
  if (!deck) return;

  selectedDeck = normalizeDeck(clone(deck));

  fetch(`https://${GetParentResourceName()}/refreshDeckBuilder`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      window.BSTAR_CARD_DEFS = data.cardCatalog || window.BSTAR_CARD_DEFS || {};
      builderOwnedCards = data.storedCards || {};
      currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));

      const refreshed = currentDecks.find(d => d.id === deck.id);
      selectedDeck = refreshed ? normalizeDeck(clone(refreshed)) : selectedDeck;

      hideAll();
      app.classList.remove('hidden');
      deckBuilderWrap.classList.remove('hidden');
      renderDeckBuilder();
      hookFilterInputs();
    });
});

deckHubDeleteBtn.addEventListener('click', () => {
  const deck = getSelectedHubDeck();
  if (!deck) return;

  openModal({
    title: 'Delete Deck',
    text: `Delete "${deck.name}"? This cannot be undone.`,
    showInput: false,
    confirmText: 'Delete',
    onConfirm: () => {
      fetch(`https://${GetParentResourceName()}/deleteDeck`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          deckBoxId: currentDeckBoxId,
          deckId: deck.id
        })
      }).then(() => {
        if (selectedHubDeckId === deck.id) {
          selectedHubDeckId = null;
        }
        setTimeout(refreshDeckHub, 150);
      });
    }
  });
});

deckHubCardsBtn.addEventListener('click', () => {
  fetch(`https://${GetParentResourceName()}/refreshDeckBox`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deckBoxId: currentDeckBoxId })
  })
    .then(res => res.json())
    .then(data => {
      currentPlayerCards = data.playerCards || {};
      currentStoredCards = data.storedCards || {};

      hideAll();
      app.classList.remove('hidden');
      deckboxWrap.classList.remove('hidden');
      renderDeckBox();
    });
});

if (duelAdvancePhaseBtn) {
  duelAdvancePhaseBtn.addEventListener('click', () => {
    const action = currentDuelState?.phase === 'draw' ? 'duelDrawCard' : 'duelAdvancePhase';

    fetch(`https://${GetParentResourceName()}/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  });
}

if (duelEndTurnBtn) {
  duelEndTurnBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duelEndTurn`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  });
}

if (duelCloseBtn) {
  duelCloseBtn.addEventListener('click', () => {
    requestDuelSurrender();
  });
}

if (duelSpawnOppBtn) {
  duelSpawnOppBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duelDebugSpawnFighter`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        playerIndex: 2,
        cardId: 'ALPH_LAYLA_HART',
        zoneIndex: 1
      })
    });
  });
}

if (duelSpawnMeBtn) {
  duelSpawnMeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duelDebugSpawnFighter`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        playerIndex: 1,
        cardId: 'ALPH_LAYLA_HART',
        zoneIndex: 1
      })
    });
  });
}

if (tableNextPhaseBtn) {
  tableNextPhaseBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duelAdvancePhase`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  });
}

if (tableEndTurnBtn) {
  tableEndTurnBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/duelEndTurn`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  });
}

if (tableSelfDeckSlot) {
  tableSelfDeckSlot.addEventListener('click', (event) => {
    event.stopPropagation();
    drawCardForTurn();
  });
}

if (tableDuelWrap) {
  tableDuelWrap.addEventListener('contextmenu', (event) => {
    event.preventDefault();
    if (clearDuelSelections()) {
      renderDuelUi();
    }
  });
}

if (tableCloseBtn) {
  tableCloseBtn.addEventListener('click', () => {
    requestDuelSurrender();
  });
}

if (tablePreviewPanel) {
  tablePreviewPanel.addEventListener('click', () => {
    if (tablePreviewCard) {
      openFullViewer(tablePreviewCard, false, false);
    }
  });
}

if (tableResultCloseBtn) {
  tableResultCloseBtn.addEventListener('click', () => {
    closeDuelUi();
  });
}

if (duelResultCloseBtn) {
  duelResultCloseBtn.addEventListener('click', () => {
    closeDuelUi();
  });
}

if (tableSelfGraveBtn) {
  tableSelfGraveBtn.addEventListener('click', (event) => event.stopPropagation());
}

if (tableOpponentGraveBtn) {
  tableOpponentGraveBtn.addEventListener('click', (event) => event.stopPropagation());
}

if (tableSelfCemeterySlot) {
  tableSelfCemeterySlot.addEventListener('click', (event) => {
    event.stopPropagation();
    openTableGraveSide = openTableGraveSide === 'self' ? null : 'self';
    renderTableGraveyard();
  });
}

if (tableOpponentCemeterySlot) {
  tableOpponentCemeterySlot.addEventListener('click', (event) => {
    event.stopPropagation();
    openTableGraveSide = openTableGraveSide === 'opponent' ? null : 'opponent';
    renderTableGraveyard();
  });
}

if (tableGravePanel) {
  tableGravePanel.addEventListener('click', (event) => event.stopPropagation());
}

if (tablePreviewPanel) {
  tablePreviewPanel.addEventListener('click', (event) => event.stopPropagation());
}

if (tableDuelWrap) {
  tableDuelWrap.addEventListener('click', (event) => {
    if (event.target.closest('.table-preview-panel')) return;
    if (event.target.closest('.table-grave-panel')) return;
    if (event.target.closest('.table-card-pile.cemetery')) return;
    closeTableGraveyard();
  });
}

if (deckSearchInput) {
  deckSearchInput.addEventListener('input', (e) => {
    builderSearchTerm = e.target.value || '';
    renderBuilderPoolCards();
  });
}

if (currentDeckNameEl) {
  currentDeckNameEl.addEventListener('click', () => {
    if (!selectedDeck) return;
    renameSelectedDeck();
  });
}

if (newDeckBtn) {
  newDeckBtn.addEventListener('click', () => {
    openModal({
      title: 'Create New Deck',
      text: 'Enter a name for the new deck.',
      showInput: true,
      inputValue: '',
      confirmText: 'Create',
      onConfirm: (value) => {
        const deckName = value || `New Deck ${Date.now()}`;

        fetch(`https://${GetParentResourceName()}/createDeck`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            deckBoxId: currentDeckBoxId,
            deckName
          })
        }).then(() => {
          setTimeout(() => refreshDeckBuilder(), 150);
        });
      }
    });
  });
}

if (saveDeckBtn) {
  saveDeckBtn.addEventListener('click', () => {
    if (!selectedDeck) return;

    normalizeDeck(selectedDeck);
    syncSelectedDeckIntoCache();

    fetch(`https://${GetParentResourceName()}/saveDeck`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        deckBoxId: currentDeckBoxId,
        deckId: selectedDeck.id,
        deckName: selectedDeck.name,
        deckData: selectedDeck.deck_data
      })
    }).then(() => {
      setTimeout(() => refreshDeckBuilder(selectedDeck.id), 150);
    });
  });
}

if (deleteDeckBtn) {
  deleteDeckBtn.addEventListener('click', () => {
    if (!selectedDeck) return;

    openModal({
      title: 'Delete Deck',
      text: `Delete "${selectedDeck.name}"? This cannot be undone.`,
      showInput: false,
      confirmText: 'Delete',
      onConfirm: () => {
        fetch(`https://${GetParentResourceName()}/deleteDeck`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            deckBoxId: currentDeckBoxId,
            deckId: selectedDeck.id
          })
        }).then(() => {
          selectedDeck = null;
          setTimeout(() => refreshDeckBuilder(), 150);
        });
      }
    });
  });
}

if (closeDeckBuilderBtn) {
  closeDeckBuilderBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/refreshDeckBuilder`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ deckBoxId: currentDeckBoxId })
    })
      .then(res => res.json())
      .then(data => {
        currentDecks = (data.decks || []).map(d => normalizeDeck(clone(d)));
        selectedHubDeckId = selectedDeck ? selectedDeck.id : (currentDecks[0]?.id || null);

        hideAll();
        app.classList.remove('hidden');
        deckHubWrap.classList.remove('hidden');
        renderDeckHub();
      });
  });
}

if (builderPreviewImage) {
  builderPreviewImage.addEventListener('click', () => {
    if (!builderPreviewImage.src) return;

    viewerOpenedFromDeckBuilder = true;
    viewerWrap.classList.remove('hidden');
    cardImage.src = builderPreviewImage.src;
    cardImage.classList.remove('zoomed');
    isZoomed = false;
    currentRotateX = 0;
    currentRotateY = 0;
    resetTilt();
    app.classList.remove('hidden');
    ensureAnimationLoop();
  });
}

cardImage.addEventListener('click', () => {
  if (viewerOpenedFromDeckBox) {
    closeFullViewer(false);
    return;
  }

  if (viewerOpenedFromDeckBuilder) {
    closeFullViewer(false);
    return;
  }

  isZoomed = !isZoomed;
  cardImage.classList.toggle('zoomed', isZoomed);
});

viewerWrap.addEventListener('click', (event) => {
  if (event.target === viewerWrap) {
    closeFullViewer();
  }
});

document.getElementById('clearFiltersBtn').addEventListener('click', () => {
  Object.keys(builderFilters).forEach(k => builderFilters[k] = '');

  builderFilters.type = 'all';
  builderFilters.rarity = 'all';

  document.querySelectorAll('.builder-filters input').forEach(i => i.value = '');
  document.getElementById('filterType').value = 'all';
  document.getElementById('filterRarity').value = 'all';

  renderBuilderPoolCards();
});

document.addEventListener('mousemove', (e) => {
  if (app.classList.contains('hidden')) return;
  if (viewerWrap.classList.contains('hidden')) return;
  if (!cardImage.src) return;

  const rect = cardImage.getBoundingClientRect();
  const centerX = rect.left + rect.width / 2;
  const centerY = rect.top + rect.height / 2;

  const activeWidth = rect.width * 1.8;
  const activeHeight = rect.height * 1.8;

  const offsetX = (e.clientX - centerX) / (activeWidth / 2);
  const offsetY = (e.clientY - centerY) / (activeHeight / 2);

  const clampedX = Math.max(-1, Math.min(1, offsetX));
  const clampedY = Math.max(-1, Math.min(1, offsetY));

  const maxTilt = isZoomed ? 10 : 6;
  targetRotateY = clampedX * maxTilt;
  targetRotateX = clampedY * -maxTilt;
});

document.addEventListener('mouseleave', () => {
  if (app.classList.contains('hidden')) return;
  resetTilt();
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (!viewerWrap.classList.contains('hidden')) {
      closeFullViewer();
      return;
    }

    if (!uiModalWrap.classList.contains('hidden')) {
      closeModal();
      return;
    }

    if (currentDuelState && (!duelWrap.classList.contains('hidden') || !tableDuelWrap.classList.contains('hidden'))) {
      requestDuelSurrender();
      return;
    }

    hideAll();
    fetch(`https://${GetParentResourceName()}/closeCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  }
});

