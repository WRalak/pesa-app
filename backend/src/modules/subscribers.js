/**
 * Side-effect imports that register domain-event subscribers and inline job
 * handlers. Imported by the API server, the worker and the test setup.
 */
import './notifications/service.js';
import './payments/service.js';
import './payments/subscribers.js';
import './budgets/subscribers.js';
import './rewards/subscribers.js';
