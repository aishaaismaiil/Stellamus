/** Authenticated Supabase client adapter; accepts a configured supabase-js client.
 * Never pass a service_role client here. Saving is explicit: no automatic upload
 * of localStorage, health information, research participants or contact lists.
 */
export function createProjectStore(client, projectSlug) {
  const allowed = new Set(['stellamus', 'lifelab', 'sensora', 'conduzpt']);
  if (!allowed.has(projectSlug)) throw new Error('Unknown project');
  async function user() {
    const { data, error } = await client.auth.getUser();
    if (error || !data?.user) throw new Error('Authentication required');
    return data.user;
  }
  function checked(result) {
    if (result.error) throw result.error;
    return result.data;
  }
  function bounded(value, limit) {
    const bytes = new TextEncoder().encode(JSON.stringify(value)).length;
    if (bytes > limit) throw new Error('Data exceeds the project limit');
    return value;
  }
  function stateKey(key) {
    if (typeof key !== 'string' || key.length < 1 || key.length > 100) throw new Error('Invalid state key');
    return key;
  }
  return {
    async load(key) {
      const actor = await user();
      const row = checked(await client.from('aisha_user_state').select('payload,updated_at')
        .eq('user_id', actor.id).eq('project_slug', projectSlug).eq('state_key', stateKey(key)).maybeSingle());
      return row;
    },
    async save(key, payload) {
      const actor = await user();
      return checked(await client.from('aisha_user_state').upsert({
        user_id: actor.id, project_slug: projectSlug, state_key: stateKey(key),
        payload: bounded(payload, 524288), updated_at: new Date().toISOString()
      }, { onConflict: 'user_id,project_slug,state_key' }).select('updated_at').single());
    },
    async remove(key) {
      const actor = await user();
      checked(await client.from('aisha_user_state').delete().eq('user_id', actor.id)
        .eq('project_slug', projectSlug).eq('state_key', stateKey(key)));
    },
    async createRun(title, mode, state = {}) {
      const actor = await user();
      if (!['guided', 'free', 'driving'].includes(mode)) throw new Error('Invalid mode');
      if (typeof title !== 'string' || !title.trim() || title.length > 200) throw new Error('Invalid title');
      return checked(await client.from('aisha_simulation_runs').insert({
        user_id: actor.id, project_slug: projectSlug, title: title.trim(), mode,
        state: bounded(state, 1048576)
      }).select('id,created_at').single());
    },
    async listRuns() {
      const actor = await user();
      return checked(await client.from('aisha_simulation_runs').select('id,title,mode,created_at,updated_at')
        .eq('user_id', actor.id).eq('project_slug', projectSlug).order('updated_at', { ascending: false }).limit(100));
    },
    async appendTurn(runId, turnNumber, payload) {
      const actor = await user();
      if (!Number.isInteger(turnNumber) || turnNumber < 0) throw new Error('Invalid turn');
      return checked(await client.from('aisha_simulation_turns').insert({
        run_id: runId, user_id: actor.id, project_slug: projectSlug, turn_number: turnNumber,
        payload: bounded(payload, 131072)
      }).select('id,created_at').single());
    },
    async feedback(message, category = 'feedback', rating = null) {
      const actor = await user();
      if (typeof message !== 'string' || message.trim().length < 5 || message.length > 3000) throw new Error('Feedback must contain 5–3000 characters');
      if (!['feedback', 'bug', 'testing'].includes(category)) throw new Error('Invalid feedback category');
      if (rating !== null && (!Number.isInteger(rating) || rating < 1 || rating > 5)) throw new Error('Invalid rating');
      return checked(await client.from('aisha_feedback').insert({
        user_id: actor.id, project_slug: projectSlug, message: message.trim(), category, rating
      }).select('id,created_at').single());
    }
  };
}
