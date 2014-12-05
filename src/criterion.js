// Generated by CoffeeScript 1.8.0
var beget, comparisonNameToOperatorMapping, criterionFactory, explodeObject, factories, flatten, getSqlFragmentParams, helper, identity, implementsSqlFragmentInterface, internals, isEmptyArray, isNegation, modifierFactories, name, operator, prototypes, some, subqueryNameToOperatorMapping, _fn, _fn1,
  __slice = [].slice;

internals = {};

helper = {};

helper.beget = beget = function(proto, properties) {
  var key, object, value, _fn;
  object = Object.create(proto);
  if (properties != null) {
    _fn = function(key, value) {
      return object[key] = value;
    };
    for (key in properties) {
      value = properties[key];
      _fn(key, value);
    }
  }
  return object;
};

helper.explodeObject = explodeObject = function(arrayOrObject) {
  var array, key, value, _fn;
  if (Array.isArray(arrayOrObject)) {
    return arrayOrObject;
  }
  array = [];
  _fn = function(key, value) {
    var object;
    object = {};
    object[key] = value;
    return array.push(object);
  };
  for (key in arrayOrObject) {
    value = arrayOrObject[key];
    _fn(key, value);
  }
  return array;
};

helper.identity = identity = function(x) {
  return x;
};

helper.isEmptyArray = isEmptyArray = function(x) {
  return Array.isArray(x) && x.length === 0;
};

helper.some = some = function(array, iterator, predicate, sentinel) {
  var i, length, result;
  if (iterator == null) {
    iterator = identity;
  }
  if (predicate == null) {
    predicate = function(x) {
      return x != null;
    };
  }
  if (sentinel == null) {
    sentinel = void 0;
  }
  i = 0;
  length = array.length;
  while (i < length) {
    result = iterator(array[i], i);
    if (predicate(result, i)) {
      return result;
    }
    i++;
  }
  return sentinel;
};

helper.flatten = flatten = function(array) {
  var _ref;
  return (_ref = []).concat.apply(_ref, array);
};

helper.implementsSqlFragmentInterface = implementsSqlFragmentInterface = function(value) {
  return (value != null) && 'function' === typeof value.sql;
};

helper.getSqlFragmentParams = getSqlFragmentParams = function(fragment) {
  return (typeof fragment.params === "function" ? fragment.params() : void 0) || [];
};

internals.prototypes = prototypes = {};

internals.factories = factories = {};

internals.modifierFactories = modifierFactories = {};

prototypes.base = {
  not: function() {
    return factories.not(this);
  },
  and: function(other) {
    return factories.and([this, other]);
  },
  or: function(other) {
    return factories.or([this, other]);
  }
};

prototypes.rawSql = beget(prototypes.base, {
  sql: function() {
    var i, params;
    if (!this._params) {
      return this._sql;
    }
    i = -1;
    params = this._params;
    return this._sql.replace(/\?/g, function() {
      i++;
      if (Array.isArray(params[i])) {
        return (params[i].map(function() {
          return "?";
        })).join(", ");
      } else {
        return "?";
      }
    });
  },
  params: function() {
    if (this._params) {
      return flatten(this._params);
    } else {
      return [];
    }
  }
});

factories.rawSql = function(sql, params) {
  if (implementsSqlFragmentInterface(sql)) {
    return sql;
  }
  return beget(prototypes.rawSql, {
    _sql: sql,
    _params: params
  });
};

helper.rawSql = factories.rawSql;

prototypes.comparison = beget(prototypes.base, {
  sql: function(escape) {
    if (escape == null) {
      escape = identity;
    }
    if (implementsSqlFragmentInterface(this._value)) {
      return "" + (escape(this._key)) + " " + this._operator + " (" + (this._value.sql(escape)) + ")";
    } else {
      return "" + (escape(this._key)) + " " + this._operator + " ?";
    }
  },
  params: function() {
    if (implementsSqlFragmentInterface(this._value)) {
      return getSqlFragmentParams(this._value);
    } else {
      return [this._value];
    }
  }
});

comparisonNameToOperatorMapping = {
  $eq: '=',
  $ne: '!=',
  $lt: '<',
  $lte: '<=',
  $gt: '>',
  $gte: '>='
};

_fn = function(name, operator) {
  return modifierFactories[name] = function(key, value) {
    return beget(prototypes.comparison, {
      _key: key,
      _value: value,
      _operator: operator
    });
  };
};
for (name in comparisonNameToOperatorMapping) {
  operator = comparisonNameToOperatorMapping[name];
  _fn(name, operator);
}

prototypes["null"] = beget(prototypes.base, {
  sql: function(escape) {
    if (escape == null) {
      escape = identity;
    }
    return "" + (escape(this._key)) + " IS " + (this._isNull ? '' : 'NOT ') + "NULL";
  },
  params: function() {
    return [];
  }
});

modifierFactories.$null = function(k, isNull) {
  return beget(prototypes["null"], {
    _key: k,
    _isNull: isNull
  });
};

prototypes.not = beget(prototypes.base, {
  innerCriterion: function() {
    return this._criterion._criterion;
  },
  sql: function(escape) {
    if (escape == null) {
      escape = identity;
    }
    if (isNegation(this._criterion)) {
      return this.innerCriterion().sql(escape);
    } else {
      return "NOT (" + (this._criterion.sql(escape)) + ")";
    }
  },
  params: function() {
    return this._criterion.params();
  }
});

isNegation = function(c) {
  return prototypes.not.isPrototypeOf(c);
};

factories.not = function(criterion) {
  return beget(prototypes.not, {
    _criterion: criterion
  });
};

prototypes.exists = beget(prototypes.base, {
  sql: function(escape) {
    if (escape == null) {
      escape = identity;
    }
    return "EXISTS (" + (this._value.sql(escape)) + ")";
  },
  params: function() {
    return getSqlFragmentParams(this._value);
  }
});

factories.exists = function(value) {
  if (!implementsSqlFragmentInterface(value)) {
    throw new TypeError('$exists key requires value that implements sql-fragment interface');
  }
  return beget(prototypes.exists, {
    _value: value
  });
};

prototypes.subquery = beget(prototypes.base, {
  sql: function(escape) {
    var questionMarks;
    if (escape == null) {
      escape = identity;
    }
    if (implementsSqlFragmentInterface(this._value)) {
      return "" + (escape(this._key)) + " " + this._operator + " (" + (this._value.sql(escape)) + ")";
    } else {
      questionMarks = [];
      this._value.forEach(function() {
        return questionMarks.push('?');
      });
      return "" + (escape(this._key)) + " " + this._operator + " (" + (questionMarks.join(', ')) + ")";
    }
  },
  params: function() {
    if (implementsSqlFragmentInterface(this._value)) {
      return getSqlFragmentParams(this._value);
    } else {
      return this._value;
    }
  }
});

subqueryNameToOperatorMapping = {
  $in: 'IN',
  $nin: 'NOT IN',
  $any: '= ANY',
  $neAny: '!= ANY',
  $ltAny: '< ANY',
  $lteAny: '<= ANY',
  $gtAny: '> ANY',
  $gteAny: '>= ANY',
  $all: '= ALL',
  $neAll: '!= ALL',
  $ltAll: '< ALL',
  $lteAll: '<= ALL',
  $gtAll: '> ALL',
  $gteAll: '>= ALL'
};

_fn1 = function(name, operator) {
  return modifierFactories[name] = function(key, value) {
    if (Array.isArray(value)) {
      if (name === '$in' || name === '$nin') {
        if (value.length === 0) {
          throw new Error("" + name + " key with empty array value");
        }
      } else {
        throw new TypeError("" + name + " key doesn't support array value. only $in and $nin do!");
      }
    } else {
      if (!implementsSqlFragmentInterface(value)) {
        if (name === '$in' || name === '$nin') {
          throw new TypeError("" + name + " key requires value that is an array or implements sql-fragment interface");
        } else {
          throw new TypeError("" + name + " key requires value that implements sql-fragment interface");
        }
      }
    }
    return beget(prototypes.subquery, {
      _key: key,
      _value: value,
      _operator: operator
    });
  };
};
for (name in subqueryNameToOperatorMapping) {
  operator = subqueryNameToOperatorMapping[name];
  _fn1(name, operator);
}

prototypes.combination = beget(prototypes.base, {
  sql: function(escape) {
    var parts;
    if (escape == null) {
      escape = identity;
    }
    parts = this._criteria.map(function(c) {
      return "(" + (c.sql(escape)) + ")";
    });
    return parts.join(" " + this._operator + " ");
  },
  params: function() {
    var params;
    params = [];
    this._criteria.forEach(function(c) {
      if (c.params != null) {
        return params = params.concat(c.params());
      }
    });
    return params;
  }
});

factories.and = function(criteria) {
  return beget(prototypes.combination, {
    _criteria: criteria,
    _operator: 'AND'
  });
};

factories.or = function(criteria) {
  return beget(prototypes.combination, {
    _criteria: criteria,
    _operator: 'OR'
  });
};

module.exports = criterionFactory = function() {
  var emptyArrayParam, firstArg, hasModifier, innerValue, key, keyCount, keys, modifier, modifierFactory, restArgs, typeOfFirstArg, value;
  firstArg = arguments[0], restArgs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  if (implementsSqlFragmentInterface(firstArg)) {
    return firstArg;
  }
  typeOfFirstArg = typeof firstArg;
  if (!('string' === typeOfFirstArg || 'object' === typeOfFirstArg)) {
    throw new TypeError("string or object expected as first argument but " + typeOfFirstArg + " given");
  }
  if (typeOfFirstArg === 'string') {
    emptyArrayParam = some(restArgs, function(x, i) {
      return {
        x: x,
        i: i
      };
    }, function(_arg) {
      var i, x;
      x = _arg.x, i = _arg.i;
      return isEmptyArray(x);
    });
    if (emptyArrayParam != null) {
      throw new Error("params[" + emptyArrayParam.i + "] is an empty array");
    }
    return factories.rawSql(firstArg, restArgs);
  }
  if (Array.isArray(firstArg)) {
    if (firstArg.length === 0) {
      throw new Error('condition-object is an empty array');
    }
    return factories.and(firstArg.map(criterionFactory));
  }
  keyCount = Object.keys(firstArg).length;
  if (0 === keyCount) {
    throw new Error('empty condition-object');
  }
  if (keyCount > 1) {
    return factories.and(explodeObject(firstArg).map(criterionFactory));
  }
  key = Object.keys(firstArg)[0];
  value = firstArg[key];
  if (value == null) {
    throw new TypeError("value undefined or null for key " + key);
  }
  if (key === '$and') {
    return factories.and(explodeObject(value).map(criterionFactory));
  }
  if (key === '$or') {
    return factories.or(explodeObject(value).map(criterionFactory));
  }
  if (key === '$not') {
    return factories.not(criterionFactory(value));
  }
  if (key === '$exists') {
    return factories.exists(value);
  }
  if ('object' !== typeof value) {
    return modifierFactories.$eq(key, value);
  }
  if (Array.isArray(value)) {
    return modifierFactories.$in(key, value);
  }
  keys = Object.keys(value);
  hasModifier = keys.length === 1 && 0 === keys[0].indexOf('$');
  if (!hasModifier) {
    return modifierFactories.$eq(key, value);
  }
  modifier = keys[0];
  innerValue = value[modifier];
  if (innerValue == null) {
    throw new TypeError("value undefined or null for key " + key + " and modifier key " + modifier);
  }
  modifierFactory = modifierFactories[modifier];
  if (modifierFactory != null) {
    return modifierFactory(key, innerValue);
  }
  throw new Error("unknown modifier key " + modifier);
};

module.exports.internals = internals;

module.exports.helper = helper;
