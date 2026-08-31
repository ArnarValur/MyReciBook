<script setup lang="ts">
// DRAFT until Arnar approves the wording — the stamp says so on the page.
// Facts sourced from the app: local-first storage, stateless extraction proxy,
// hashed purchase-token cap counter, crash reporting with keys and file paths stripped.
useSeoMeta({
  title: 'Privacy — MyReciBook',
  description:
    'Your recipes live on your phone, not with us. What stays local, what the AI rescue sends and why, and what MyReciBook never does.',
})
</script>

<template>
  <section class="section">
    <div class="doc-card paper ruled">
      <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1deg)" />
      <span class="doc-draft">Draft — not fully baked through</span>
      <h1>Privacy</h1>
      <p class="doc-meta">The short version: your recipes live on your phone, not with us.</p>

      <h2>What stays on your phone</h2>
      <p>
        Your cookbook — recipes, photos, pantry, food diary, tags — is plain
        files in a folder <strong>you</strong> choose on your device. We have no
        server that stores them, no account that holds them. Delete the app and
        the files are still yours.
      </p>

      <h2>What leaves your phone, and why</h2>
      <ul>
        <li><strong>AI rescues.</strong> When you import a screenshot, link or photo, its content is sent to our extraction service, which passes it to Google's Gemini model to be structured into a recipe, and hands the result back. It is used to answer that one request. We do not keep it.</li>
        <li><strong>The rescue counter.</strong> To count AI rescues against your included 1,200 we key the tally to a one-way hash of your Play purchase token. We cannot read your identity out of it.</li>
        <li><strong>Barcodes.</strong> Scanning a package queries the Open Food Facts database for that barcode.</li>
        <li><strong>Crash reports.</strong> On by default so we can fix what breaks. Before anything is sent we strip out API keys, tokens, file names and folder paths — an error message can still carry a fragment of the text that broke, which is what makes it fixable. You can turn it off in Settings.</li>
        <li><strong>Your own cloud, if you connect it.</strong> Backup and export to Google Drive or Dropbox go to <strong>your</strong> account, under your control. We never see those files.</li>
      </ul>

      <h2>What we never do</h2>
      <ul>
        <li>No accounts, no sign-up, no email collection.</li>
        <li>No ads, no selling or sharing data with data brokers.</li>
        <li>No storing your recipes on our servers.</li>
      </ul>

      <h2>Payment</h2>
      <p>
        Purchases run through Google Play. We receive the purchase token to
        unlock the app and meter the AI cap — Google handles the payment
        details, we never see them.
      </p>

      <h2>Questions</h2>
      <p>Write us — see the <NuxtLink to="/contact" style="color: var(--box-primary)">contact card</NuxtLink>.</p>
    </div>
  </section>
</template>
