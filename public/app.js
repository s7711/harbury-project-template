async function callApi(path, outEl) {
  outEl.textContent = "Loading…";
  try {
    const res = await fetch(path);
    const data = await res.json().catch(() => null);
    if (!res.ok) {
      const detail = data && data.error ? data.error : res.statusText;
      outEl.textContent = "Error " + res.status + ": " + detail;
      return;
    }
    outEl.textContent = JSON.stringify(data, null, 2);
  } catch (err) {
    outEl.textContent = "Error: " + err.message;
  }
}

document.getElementById("hello-btn").addEventListener("click", () => {
  callApi("/api/hello", document.getElementById("hello-out"));
});

document.getElementById("notes-btn").addEventListener("click", () => {
  callApi("/api/notes", document.getElementById("notes-out"));
});
